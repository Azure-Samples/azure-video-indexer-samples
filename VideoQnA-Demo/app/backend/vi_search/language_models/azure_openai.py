'''
This was implemented with the help of the following resource:
    Azure OpenAI Samples
    https://github.com/Azure/azure-openai-samples/blob/main/quick_start/v1/01_OpenAI_getting_started.ipynb
'''
import logging
import os

from openai import AzureOpenAI
from tenacity import retry, stop_after_attempt, wait_random_exponential
import tiktoken

from vi_search.utils.azure_utils import get_azd_env_values
from .language_models import LanguageModels


logger = logging.getLogger(__name__)


class OpenAI(LanguageModels):
    def __init__(self):
        env_values = get_azd_env_values()
        azure_openai_service = env_values['AZURE_OPENAI_SERVICE']
        azure_openai_key = env_values['AZURE_OPENAI_API_KEY']
        self.client = AzureOpenAI(azure_endpoint=f"https://{azure_openai_service}.openai.azure.com/",
                                  api_key=azure_openai_key,
                                  api_version="2024-02-01")

        self.azure_openai_chatgpt_deployment = env_values['AZURE_OPENAI_CHATGPT_DEPLOYMENT']
        self.azure_openai_embeddings_deployment = env_values['AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT']

    def count_tokens(self, text: str) -> int:
        ''' Count tokens in text. '''
        encoding = tiktoken.get_encoding("cl100k_base")  # For gpt-4, gpt-3.5-turbo, etc.
        tokens = encoding.encode(text)
        return len(tokens)

    def get_tokes_limit(self) -> int:
        ''' Get token limit for the model. '''
        # FIXME: Get the actual limit with reference to the `self.model`
        return 4096

    def get_embeddings_size(self) -> int:
        ''' Get embeddings size for the model.'''
        return 1536

    @retry(wait=wait_random_exponential(min=1, max=60), stop=stop_after_attempt(6))
    def _completion_with_backoff(self, input, model):
        return self.client.embeddings.create(input=input, model=model)

    def get_text_embeddings(self, text: str) -> list[float]:
        ''' Encode text - return a vector representation of the text. '''
        if self.count_tokens(text) > self.get_embeddings_size():
            logger.warning(f"Text exceeds token limit: {self.count_tokens(text)} > {self.get_embeddings_size()}")

        response = self._completion_with_backoff(input=text, model=self.azure_openai_embeddings_deployment)
        embeddings_vector = response.data[0].embedding
        return embeddings_vector

    def chat(self, sys_prompt: str, user_prompt: str, temperature: float, top_p: float = 1.0) -> str:
        ''' Chat with the OpenAI model.

        :param sys_prompt: The system prompt to chat with
        :param user_prompt: The user prompt to chat with
        :param temperature: The temperature to use for chat
        :param top_p: The top_p to use for chat
        :return: The response from the chat model
        '''

        messages = [{"role": "system", "content": sys_prompt},
                    {"role": "user", "content": user_prompt},]

        res = self.client.chat.completions.create(model=self.azure_openai_chatgpt_deployment,
                                                  messages=messages,
                                                  temperature=temperature,
                                                  top_p=top_p)
        content = res.choices[0].message.content

        # FIXME: Instead of raising an exception, we should return a proper error message
        if res.choices[0].finish_reason == 'content_filter':
            logger.warning('Content filter triggered')
            content = 'SYSTEM: Content filter triggered'
        elif content is None:
            logger.warning('No content returned')
            content = 'SYSTEM: No content returned'

        return content
