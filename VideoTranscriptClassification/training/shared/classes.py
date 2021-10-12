import torch


class EncodedDataset(torch.utils.data.Dataset):  # noqa D103  # TODO: Remove this ignore
    def __init__(  # noqa D107  # TODO: Remove this ignore
        self, df, tokenizer, return_iid=False
    ):
        self.df = df
        self.tokenizer = tokenizer
        self.return_iid = return_iid

    def __getitem__(self, idx):  # noqa D105  # TODO: Remove this ignore
        info = self.df.iloc[idx]
        encodings = self.tokenizer.encode_plus(
            info.transcript, padding="max_length", truncation=True
        )
        item = {key: torch.tensor(val) for key, val in encodings.items()}
        item["labels"] = torch.tensor(info.target)
        if self.return_iid:
            item["iid"] = info.name
        return item

    def __len__(self):  # noqa D105  # TODO: Remove this ignore
        return len(self.df)
