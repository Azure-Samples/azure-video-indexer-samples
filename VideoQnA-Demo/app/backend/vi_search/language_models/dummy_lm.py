from .language_models import LanguageModels


class DummyLanguageModels(LanguageModels):
    ''' Dummy Language Models class for testing purposes.
        No real tokenizer, embeddings or chat models are used.
    '''
    def __init__(self, embeddings_size: int = 256):
        super().__init__()
        self.embeddings_size = embeddings_size

    def count_tokens(self, text: str) -> int:
        ''' Count tokens in text. '''
        return len(text.split())

    def get_tokes_limit(self) -> int:
        ''' Get token limit for the model. '''
        return 4096

    def get_embeddings_size(self) -> int:
        return self.embeddings_size

    def get_text_embeddings(self, text: str) -> list[float]:
        ''' For each word, get division of 1st character ascii by word length.
            Truncate or pad by 0's to `self.embeddings_size`, which defaults to 256.
        '''
        vector = [ord(word[0]) / len(word) for word in text.split()]

        # Truncate vector at embeddings_size or pad with 0s to embeddings_size
        vector += [0] * (self.embeddings_size - len(vector))
        vector = vector[:self.embeddings_size]

        assert len(vector) == self.embeddings_size
        return vector

    def chat(self, sys_prompt: str, user_prompt: str, temperature: float, top_p: float = 1.0) -> str:
        ''' Dummy chat model - echo back the input prompt.

        :param sys_prompt: The system prompt to chat with
        :param user_prompt: The user prompt to chat with
        :param temperature: The temperature to use for chat
        :param top_p: The top_p to use for chat
        '''

        response = f"Let me just repeat your input:\n[{sys_prompt=}], [{user_prompt=}], [{temperature=}], [{top_p=}]"
        return response
