import logging

import chromadb
from chromadb.api import ClientAPI

from .prompt_content_db import nonewlines, PromptContentDB, VECTOR_FIELD_NAME
from vi_search.constants import CHROMA_DB_DIR


logger = logging.getLogger(__name__)


class ChromaDB(PromptContentDB):
    def __init__(self, persist_directory=None) -> None:
        '''
        :param persist_directory: The directory where the collection will be stored
        '''
        super().__init__()

        # Create a new Chroma client with persistence enabled
        self._persist_directory = persist_directory or CHROMA_DB_DIR
        path = str(self._persist_directory)
        print(f"ChromaDB: Using persist directory: {path}")
        self.client: ClientAPI = chromadb.PersistentClient(path=path)

    def create_db(self, name: str, vector_search_dimensions: int) -> None:
        ''' Create new or get existing chromadb collection.

        :param name: The name of the collection
        :param vector_search_dimensions: The number of dimensions of the embeddings
        '''
        collection = self.client.get_or_create_collection(name)
        self.db_name = name
        self.db_handle = collection

    def remove_db(self, name: str) -> None:
        """ Removes collection. """
        collections = self.client.list_collections()
        for collection in collections:
            if collection.name == name:
                self.client.delete_collection(name)
                print(f"Collection {name} deleted")
                return

        print(f"Collection {name} not found")

    def get_available_dbs(self) -> list[str]:
        ''' Get the list of available collections. '''
        collections = self.client.list_collections()
        collection_names = [collection.name for collection in collections]
        return collection_names

    def set_db(self, name: str) -> None:
        collection = self.client.get_collection(name)
        self.db_name = name
        self.db_handle = collection

    def add_entry_batch(self, entry_batch):
        ''' Add entry batch to the collection.

        :param entry_batch: List of entries to be added to the collection
        '''
        data = self._transform_sections_to_chromadb_format(entry_batch)
        self.db_handle.add(**data)

    @staticmethod
    def _transform_sections_to_chromadb_format(batch):
        """ Pivot sections into a format suitable for chromadb. """

        ids = []
        documents = []
        embeddings = []
        metadatas = []
        for s in batch:
            ids.append(s.pop('id'))
            documents.append(s.pop('content'))
            embeddings.append(s.pop(VECTOR_FIELD_NAME))
            metadatas.append(s)

        data = {
            'ids': ids,
            'documents': documents,
            'embeddings': embeddings,
            'metadatas': metadatas
        }

        return data

    def vector_search(self, embeddings_vector, n_results=3) -> tuple[dict, list[str]]:
        ''' Query the collection with the given embeddings vector.

        :param embeddings_vector: embeddings vector to search in the collection
        :param n_results: Number of results to return
        '''
        results = self.db_handle.query(query_embeddings=[embeddings_vector], n_results=n_results)

        docs_by_id = {}
        results_content = []
        for idx, uid in enumerate(results['ids'][0]):
            docs_by_id[uid] = results['metadatas'][0][idx]
            docs_by_id[uid].update({'content': results['documents'][0][idx]})
            docs_by_id[uid].update({'distance': results['distances'][0][idx]})
            results_content.append(f'{uid}: {nonewlines(results["documents"][0][idx])}')

        return docs_by_id, results_content

    def get_collection_data(self):
        ''' Get collection's data. '''

        all_data = self.db_handle.get(include=['embeddings', 'documents', 'metadatas'])
        return all_data
