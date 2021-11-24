import pickle
from pathlib import Path

import click
import pandas as pd
from azureml.core import Dataset, Run
from shared.utils import seed_everything

from prep_data.dataset_loader import DatasetLoader


@click.command()
@click.option(
    "--drop_empty_transcripts",
    default=True,
    type=bool,
)
@click.option(
    "--min_samples_in_class",
    default=20,
    type=int,
)
@click.option(
    "--label_encoder_output_path",
    default="./outputs/label_encoder.pickle",
    type=str,
)
@click.option(
    "--dataset_version_output_path",
    default="./outputs/dataset_version.txt",
    type=str,
)
@click.option(
    "--dataset_name",
    default="df_kaos",
    type=str,
)
@click.option(
    "--target_column",
    default="high_label",
    type=str,
)
def main(  # noqa D103  # TODO: Remove this ignore
    drop_empty_transcripts=True,
    min_samples_in_class=20,
    label_encoder_output_path="./outputs/label_encoder.pickle",
    dataset_version_output_path="./outputs/dataset_version.txt",
    dataset_name="df_kaos",
    target_column="high_label"
):
    seed_everything()
    run = Run.get_context()
    experiment = run.experiment
    ws = experiment.workspace

    args = {
        "drop_empty_transcripts": drop_empty_transcripts,
        "min_samples_in_class": min_samples_in_class,
        "target_column": target_column
    }

    for k, v in args.items():
        run.tag(k, str(v))
        run.parent.tag(k, str(v))

    df = Dataset.get(ws, dataset_name).to_pandas_dataframe()

    ds_loader = DatasetLoader(ws, run)

    df: pd.DataFrame = ds_loader.load_df(
        df,
        target_column=target_column,
        drop_empty_transcripts=drop_empty_transcripts,
        min_samples_in_class=min_samples_in_class,
    )

    args["train_set_size"] = ds_loader.train_set_size
    args["valid_set_size"] = ds_loader.valid_set_size

    data_output_path = Path(f"data_df_{experiment.id}_{run.id}.csv")

    df.to_csv(str(data_output_path), index=False)

    with open(label_encoder_output_path, "wb") as f:
        pickle.dump(ds_loader.le, f, protocol=pickle.HIGHEST_PROTOCOL)

    datastore = ws.get_default_datastore()

    datastore.upload_files([str(data_output_path.absolute())])

    datastore_paths = [(datastore, str(data_output_path))]
    dataset = Dataset.Tabular.from_delimited_files(path=datastore_paths)

    dataset = dataset.register(
        workspace=ws,
        name="kaos_" + target_column,
        description="Dataset used during model training",
        create_new_version=True,
        tags=args,
    )

    with open(dataset_version_output_path, "w") as f:
        f.write(str(dataset.version))


if __name__ == "__main__":
    main()
