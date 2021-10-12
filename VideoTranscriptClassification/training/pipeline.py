import click

from azureml.core import Environment, Experiment, ScriptRunConfig, Workspace
from azureml.core.authentication import AzureCliAuthentication
from azureml.core.conda_dependencies import CondaDependencies
from azureml.core.environment import DEFAULT_CPU_IMAGE, DEFAULT_GPU_IMAGE
from azureml.core.runconfig import PyTorchConfiguration
from azureml.pipeline.core import Pipeline, PipelineData, PipelineEndpoint
from azureml.pipeline.steps import CommandStep, PythonScriptStep
from azureml.core.compute import ComputeTarget, AmlCompute
from azureml.core.compute_target import ComputeTargetException


def create_environment(  # noqa D103  # TODO: Remove this ignore
    env_name,
    python_version,
    pip_packages,
    conda_packages=[],
    conda_channels=[],
    use_docker=True,
    use_gpu=True,
):
    pip_packages.append("azureml-core==1.33.*")
    env = Environment(env_name)
    env.python.conda_dependencies = CondaDependencies.create(
        python_version=python_version,
        pip_packages=pip_packages,
        conda_packages=conda_packages,
    )
    for channel in conda_channels:
        env.python.conda_dependencies.add_channel(channel)

    if use_docker:
        env.docker.enabled = True
        env.docker.base_image = DEFAULT_GPU_IMAGE if use_gpu else DEFAULT_CPU_IMAGE
    else:
        env.docker.enabled = False

    return env


def get_or_create_compute_target(ws, gpu=True):
    cluster_name = "gpu-cluster" if gpu else "cpu-cluster"
    # Verify that the cluster does not exist already
    try:
        cluster = ComputeTarget(workspace=ws, name=cluster_name)
        print('Found existing cluster, use it.')
    except ComputeTargetException:
        compute_config = AmlCompute.provisioning_configuration(
            vm_size='STANDARD_NC24' if gpu else 'STANDARD_DS3_V2',
            max_nodes=8, 
            idle_seconds_before_scaledown=600)
        cluster = ComputeTarget.create(ws, cluster_name, compute_config)

    cluster.wait_for_completion(show_output=True)
    return cluster_name


@click.command()
@click.option(
    "--experiment_name",
    type=str,
    default="kaosexp",
)
@click.option(
    "--dataset_name",
    type=str,
    default="df_kaos",
)
@click.option(
    "--target_column",
    default='high_label',
    type=str,
)
def main(  # noqa D103  # TODO: Remove this ignore
    experiment_name: str = "kaosexp",
    dataset_name: str = "df_kaos",
    target_column: str = "high_label",
    num_nodes: int = 3,
    num_gpu_per_node: int = 4,
):
    ws = Workspace.from_config()
    cpu_compute_target = get_or_create_compute_target(ws, gpu=False)
    gpu_compute_target = get_or_create_compute_target(ws, gpu=True)
    experiment = Experiment(workspace=ws, name=experiment_name)

    base_packages = [
        "azureml-core==1.33.0",
        "azureml-dataprep==2.22.1",
        "scikit-learn==0.24",
        "pandas==1.3.1",
        "matplotlib==3.4.3",
        "langdetect==1.0.9",
        "click==8.0.1",
        "pyarrow==5.0.0",
        "requests==2.26.0",
    ]
    cpu_env = create_environment(
        env_name="cpuenv",
        python_version="3.8.10",
        pip_packages=base_packages,
        use_gpu=False
    )
    gpu_env = create_environment(
        env_name="gpuenv",
        python_version="3.8.10",
        pip_packages=base_packages + [
            "transformers==4.9.1",
            "torch==1.8",
        ],
        conda_packages=["pytorch", "torchvision", "cudatoolkit=10.2"],
        conda_channels=["pytorch"],
        use_gpu=True,
    )

    cpu_config = ScriptRunConfig(
        source_directory=".",
        compute_target=cpu_compute_target,
        environment=cpu_env,
    )
    gpu_config = ScriptRunConfig(
        source_directory=".",
        compute_target=gpu_compute_target,
        environment=gpu_env,
    )

    trained_model_output = PipelineData(name="trained_model", is_directory=True)
    # we use this PipelineData object as shared space for our clusters nodes
    # pytorch distributed training dumps checkpoints, weights and gradients in there
    temp_output_share = PipelineData(name="temp_output_share", is_directory=True)
    dataset_version_output = PipelineData(name="dataset_version")

    launch_cmd = [
        'PYTHONPATH="."',
        "python",
        "-m",
        "torch.distributed.launch",
        "--nproc_per_node",
        num_gpu_per_node,
        "--nnodes",
        num_nodes,
        "--node_rank",
        "$NODE_RANK",
        "--master_addr",
        "$MASTER_ADDR",
        "--master_port",
        "$MASTER_PORT",
        "--use_env",
        "train_model/train.py",
        "--save_model_path",
        trained_model_output,
        "--temp_output_share",
        temp_output_share,
        "--dataset_version_input_path",
        dataset_version_output,
        "--target_column",
        target_column,
    ]

    distributed_config = ScriptRunConfig(
        source_directory=".",
        command=launch_cmd,
        compute_target=gpu_compute_target,
        environment=gpu_env,
        distributed_job_config=PyTorchConfiguration(node_count=num_nodes),
    )

    train_step = CommandStep(
        name="train_model",
        runconfig=distributed_config,
        source_directory=".",
        inputs=[dataset_version_output],
        outputs=[trained_model_output, temp_output_share],
    )

    labelencoder_output = PipelineData(name="label_encoder")

    dataprep_step = PythonScriptStep(
        name="load_and_register_data",
        script_name="prep_data/prep.py",
        arguments=[
            "--min_samples_in_class",
            20,
            "--label_encoder_output_path",
            labelencoder_output,
            "--dataset_version_output_path",
            dataset_version_output,
            "--target_column",
            target_column,
        ],
        runconfig=cpu_config.run_config,
        outputs=[labelencoder_output, dataset_version_output],
    )

    evaluate_step = PythonScriptStep(
        name="evaluate_model",
        script_name="evaluate/evaluate_model.py",
        arguments=[
            "--model_path",
            trained_model_output,
            "--label_encoder_path",
            labelencoder_output,
            "--dataset_version_input_path",
            dataset_version_output,
            "--target_column",
            target_column,
        ],
        runconfig=gpu_config.run_config,
        inputs=[trained_model_output, labelencoder_output, dataset_version_output],
    )

    register_model_step = PythonScriptStep(
        name="register_model",
        script_name="register_model/register_model.py",
        arguments=[
            "--model_path",
            trained_model_output,
            "--label_encoder_path",
            labelencoder_output,
            "--target_column",
            target_column,
        ],
        runconfig=cpu_config.run_config,
        inputs=[trained_model_output, labelencoder_output],
    )
    register_model_step.run_after(evaluate_step)

    steps = [dataprep_step, train_step, evaluate_step, register_model_step]

    pipeline = Pipeline(workspace=ws, steps=steps)

    pipeline_run = experiment.submit(pipeline)  # Returns pipeline_run

    print(f"Pipeline_run: {pipeline_run}")


if __name__ == "__main__":
    main()
