import json
import pickle
from distutils.dir_util import copy_tree

import click
import torch
from azureml.core import Dataset, Run
from shared.utils import seed_everything
from transformers import AutoModelForSequenceClassification, AutoTokenizer

from evaluate.evaluation import (
    calculate_classification_metrics,
    create_results_df,
    plot_confusion_matrix,
)


@click.command()
@click.option(
    "--model_path",
    default="./outputs/best_model",
    type=str,
)
@click.option(
    "--label_encoder_path",
    default="./outputs/label_encoder.pickle",
    type=str,
)
@click.option(
    "--dataset_version_input_path",
    type=str,
    default="./outputs/dataset_version.txt"
)
@click.option(
    "--target_column",
    required=True,
    type=str,
)
def main(  # noqa D103  # TODO: Remove this ignore
    target_column,
    model_path="./outputs/best_model",
    label_encoder_path="./outputs/label_encoder.pickle",
    dataset_version_input_path="./outputs/dataset_version.txt",
    dataset_name="kaos_edu_videos",
):
    seed_everything()
    run = Run.get_context()
    experiment = run.experiment
    ws = experiment.workspace

    args = {
        "target_column": target_column,
    }

    for k, v in args.items():
        run.tag(k, str(v))

    print(f"cuda available: {torch.cuda.is_available()}")

    with open(dataset_version_input_path, "r") as f:
        version = f.readline()

    dataset = Dataset.get_by_name(
        ws,
        name="kaos_" + target_column,
        version=version)
    df = dataset.to_pandas_dataframe()
    df.set_index("video_id", inplace=True)

    tokenizer = AutoTokenizer.from_pretrained(model_path)
    model = AutoModelForSequenceClassification.from_pretrained(model_path)
    print("loaded model and tokenizer")
    model.eval()

    with open(label_encoder_path, "rb") as handle:
        le = pickle.load(handle)
    print("loaded label encoder")
    print(le.classes_)

    results_df, embeddings = create_results_df(model, tokenizer, df, le)
    results_df.to_csv("./outputs/results.csv", index=True)
    plot_confusion_matrix(results_df, le.classes_)

    metrics = calculate_classification_metrics(
        results_df[results_df.is_valid == True]  # noqa E712
    )

    with open("metrics.json", "w+") as f:
        json.dump(metrics, f)

    key_set = {"accuracy", "macro avg", "weighted avg"}

    for key, values in metrics.items():
        if key in key_set:
            if isinstance(values, dict):
                for v_k, v_v in values.items():
                    run.log(f"{key}_{v_k}", v_v)
            else:
                run.log(key, values)

    # copy azureml outputs
    copy_tree(model_path, "./outputs/best_model")


if __name__ == "__main__":
    main()
