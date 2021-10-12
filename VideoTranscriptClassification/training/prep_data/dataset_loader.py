import pandas as pd
from sklearn import preprocessing
from sklearn.model_selection import train_test_split


class DatasetLoader:  # noqa D103  # TODO: Remove this ignore
    def __init__(self, ws, run):  # noqa D107  # TODO: Remove this ignore
        self.ws = ws
        self.run = run
        self.le = preprocessing.LabelEncoder()

        self.train_set_size = None
        self.valid_set_size = None

    def load_df(
        self,
        df,
        target_column,
        drop_empty_transcripts=True,
        min_samples_in_class=20,
    ):
        """
        Return a dataframe.

        With video_id as the index and the columns
        ['target_label', 'transcript', 'is_valid', 'target'].
        Where target_label is a string and target is an int
        """
        print("Preparing dataset for target_column: ", target_column)
        df = df.rename(columns={target_column: "target_label"})
        df = df.drop(
            columns=[
                "vi_video_id",
                "video_path",
        ])

        df = df.rename(
            columns={
                "transcript_text": "transcript",
                "video_name": "video_id",
            }
        )

        if drop_empty_transcripts:
            print("dropping empty transcripts")
            pre_drop_len = len(df)
            df = self.remove_empty_transcripts(df)
            self.run.log("num_dropped_no_transcript", pre_drop_len - len(df))

        print("Dropping categories with less than %s examples" % min_samples_in_class)
        pre_drop_len = len(df)
        df = df[
            df.groupby("target_label")["target_label"].transform("size")
            >= min_samples_in_class
        ]
        self.run.log("num_dropped_less_than_min_in_class", pre_drop_len - len(df))

        print("splitting into train and val sets")
        df = self.split_df_sets(df=df)

        print("encoding targets")
        df = self.encode_targets(df)

        self.run.log("num_classes", len(df.target.unique()))
        self.run.log("class_names", df.target.unique())

        return df

    def split_df_sets(  # noqa D103  # TODO: Remove this ignore
        self, df, stratify_colname="target_label"
    ):

        train_df, valid_df = train_test_split(
            df, stratify=df[stratify_colname], random_state=42
        )

        df.loc[train_df.index.tolist(), "is_valid"] = False
        df.loc[valid_df.index.tolist(), "is_valid"] = True

        self.train_set_size = len(df[df.is_valid == False])  # noqa E712
        self.valid_set_size = len(df[df.is_valid == True])  # noqa E712

        self.run.log("train_set_size", self.train_set_size)
        self.run.log("valid_set_size", self.valid_set_size)

        return df

    def encode_targets(self, df):  # noqa D103  # TODO: Remove this ignore
        df["target"] = self.le.fit_transform(df.target_label)
        return df
        
    def remove_empty_transcripts(  # noqa D103  # TODO: Remove this ignore
        self, df, transcript_colname="transcript"
    ):
        return df[df[transcript_colname].str.len > 0]
