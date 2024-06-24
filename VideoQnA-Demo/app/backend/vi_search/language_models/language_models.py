from abc import ABC, abstractmethod


class LanguageModels(ABC):
    ''' Language models interface.
        1. Generative models (e.g. GPT-3, GPT-4)
        2. Embeddings models (e.g. ada-002, BERT, RoBERTa)
        Notice they do not have to be related at all as the embeddings are used for the vector search and
        the generative model is used to validate and consolidate the search results.
    '''
    def __init__(self):
        pass

    @abstractmethod
    def count_tokens(self, text: str) -> int:
        ''' Count tokens in text. '''
        pass

    @abstractmethod
    def get_tokes_limit(self) -> int:
        ''' Get token limit for the model. '''
        pass

    @abstractmethod
    def get_embeddings_size(self) -> int:
        ''' Get embeddings size for the model.'''
        pass

    @abstractmethod
    def get_text_embeddings(self, text: str) -> list[float]:
        ''' Encode text - return a vector representation of the text. '''
        pass

    @abstractmethod
    def chat(self, sys_prompt: str, user_prompt: str, temperature: float, top_p: float = 1.0) -> str:
        pass
