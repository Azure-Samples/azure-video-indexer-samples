import os
from itertools import chain
import click
from azureml.core import Run, Dataset

from train_model.model_trainer import ModelTrainer
from shared.utils import seed_everything


@click.command()
@click.option(
    "--save_model_path",
    type=str,
    default="./outputs/best_model",
)
@click.option(
    "--temp_output_share",
    type=str,
    default="./outputs",
)
@click.option(
    "--dataset_version_input_path",
    type=str,
    default="./outputs/dataset_version.txt",
)
@click.option(
    "--num_epochs",
    default=15,
    type=int,
)
@click.option(
    "--target_column",
    required=True,
    type=str,
)
def main(  # noqa D103  # TODO: Remove this ignore
    target_column,
    save_model_path="./outputs/best_model",
    temp_output_share="./outputs",
    dataset_version_input_path="./outputs/dataset_version.txt",
    num_epochs=15,
):
    seed_everything()
    run = Run.get_context()
    experiment = run.experiment
    ws = experiment.workspace

    args = {
        "num_epochs": num_epochs,
        "target_column": target_column
    }

    for k, v in args.items():
        run.tag(k, str(v))

    with open(dataset_version_input_path, "r") as f:
        version = f.readline()

    dataset = Dataset.get_by_name(
        ws,
        name="kaos_" + target_column,
        version=version)
    df = dataset.to_pandas_dataframe()

    agg = df[["target_label", "target"]].groupby(["target_label"]).first()
    class_lookup = dict(
        zip(
            agg.index.tolist(),
            # needed to convert from int64 to int
            [int(v) for v in chain.from_iterable(agg.values)],
        )
    )
    print(class_lookup)

    os.makedirs(temp_output_share, exist_ok=True)
    model_trainer = ModelTrainer(
        df,
        output_dir=temp_output_share,
        class_lookup=class_lookup,
        num_epochs=num_epochs,
    )
    model, trainer, tokenizer = model_trainer.run_trainer()

    print("saving model")
    trainer.save_model(save_model_path)


if __name__ == "__main__":
    main()
