from abc import ABC, abstractmethod
import re

from vi_search.prompt_content_db.prompt_content_db import PromptContentDB
from vi_search.language_models.language_models import LanguageModels
from vi_search.utils.ask_templates import ask_templates


def get_references_from_chat_answer(answer, valid_uids):
    ''' Returns the sections UIDs from the answer.
        Notice this is very dependent on the chat model output format - which was passed in the prompt examples.
    '''
    results = re.findall(r'\[(.*?)\]', answer)

    sections_uids = []
    for res in results:
        sections_uids.extend(res.split(','))

    clean_sections_uids = []
    for uid in sections_uids:
        uid = uid.strip()
        if uid not in valid_uids:
            print(f"WARNING: {uid=} not in valid UIDs. ignoring.")
            continue

        clean_sections_uids.append(uid)

    clean_sections_uids = list(set(clean_sections_uids))  # Remove duplicates
    return clean_sections_uids


class Approach(ABC):
    @abstractmethod
    def run(self, q: str, overrides: dict) -> dict:
        raise NotImplementedError


class RetrieveThenReadVectorApproach(Approach):
    """ Simple retrieve-then-read implementation, using the Cognitive Search and OpenAI APIs directly.
        It first retrieves top documents from search, then constructs a prompt with them, and then uses OpenAI to
        generate an completion (answer) with that prompt. """

    def __init__(self, prompt_content_db: PromptContentDB, language_models: LanguageModels, extract_references=False,
                 ask_template_key="default", temperature=1.0, top_p=1.0, top_n=3):
        self.prompt_content_db = prompt_content_db
        self.language_models = language_models
        self.extract_references = extract_references
        self.system_prompt = ask_templates[f"{ask_template_key}_system_prompt"]
        self.user_template = ask_templates[f"{ask_template_key}_user_template"]
        self.temperature = temperature
        self.top_p = top_p
        self.top_n = top_n

    def run(self, q: str, overrides: dict) -> dict:
        """ Implemented in two steps:
            1. Search most relevant sections to the question in the prompt_content DB based on vector search.
            2. Inject closest results to a the prompt and generate an answer from a chat model.
        """

        db_name = overrides.get("index")
        retrieval_n = overrides.get("top", self.top_n)

        if db_name is not None and self.prompt_content_db.db_name != db_name:
            self.prompt_content_db.set_db(db_name)

        embeddings_vector = self.language_models.get_text_embeddings(q)
        docs_by_id, results_content = self.prompt_content_db.vector_search(embeddings_vector, n_results=retrieval_n)
        all_content = "\n".join(results_content)

        sys_prompt = overrides.get("sys_prompt", self.system_prompt)
        user_prompt = (overrides.get("user_template", self.user_template)).format(q=q, retrieved=all_content)

        temperature = overrides.get("temperature", self.temperature)
        top_p = overrides.get("top_p", self.top_p)

        completion = self.language_models.chat(sys_prompt=sys_prompt, user_prompt=user_prompt, temperature=temperature,
                                               top_p=top_p)

        result = {"data_points": results_content,  # List of search results
                  "answer": completion,    # Chat GPT answer
                  "thoughts": f"Question:<br>{q}<br><br>Prompt:<br>" + sys_prompt.replace('\n', '<br>'),  # Question + Prompt
                  "docs_by_id": docs_by_id,  # Same as data_points, but dict indexed by ID
                  }

        if self.extract_references:
            result["references"] = get_references_from_chat_answer(result["answer"], valid_uids=docs_by_id.keys())

        return result
