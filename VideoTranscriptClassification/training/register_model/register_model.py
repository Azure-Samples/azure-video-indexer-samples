import shutil

import click
from azureml.core import Run


@click.command()
@click.option(
    "--model_path",
    type=str,
    default="./outputs/best_model",
)
@click.option(
    "--target_column",
    required=True,
    type=str,
)
@click.option(
    "--label_encoder_path",
    type=str,
    default="./outputs/label_encoder.pickle",
)
def main(  # noqa D103  # TODO: Remove this ignore
    target_column,
    model_path="./outputs/best_model",
    label_encoder_path="./outputs/label_encoder.pickle",
):
    """Registration step is PythonScriptStep in AML Training pipeline."""
    run = Run.get_context()
    experiment = run.experiment
    ws = experiment.workspace

    args = {
        "target_column": target_column
    }

    for k, v in args.items():
        run.tag(k, str(v))
        run.parent.tag(k, str(v))

    print("Copying labels encoder file to models path..")
    shutil.copy(label_encoder_path, model_path)

    run.parent.upload_folder(model_path, model_path)
    print("Registering the model in AML..")
    model = run.parent.register_model(
        model_name="kaos_" + target_column,
        model_path=model_path,
        description=f"Model to predict transcripts categories.",
        tags={"target_column": target_column},
    )
    print("Name:", model.name)
    print("Version:", model.version)


if __name__ == "__main__":
    main()
