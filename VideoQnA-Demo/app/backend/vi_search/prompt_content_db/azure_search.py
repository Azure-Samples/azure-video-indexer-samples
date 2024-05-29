'''
This was implemented with the help of the following resource:
    Azure Cognitive Search - Vector Python Sample
    https://github.com/Azure/azure-search-vector-samples/blob/5773a187047f6afbbe2dcbf1f641126a49a5fe7e/demo-python/code/basic-vector-workflow/azure-search-vector-python-sample.ipynb#L428
'''

import logging
import time
from typing import Optional

from azure.core.credentials import AzureKeyCredential
from azure.identity import AzureDeveloperCliCredential
from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SimpleField,
    SearchFieldDataType,
    SearchableField,
    SearchField,
    VectorSearch,
    HnswAlgorithmConfiguration,
    VectorSearchProfile,
    SemanticConfiguration,
    SemanticPrioritizedFields,
    SemanticField,
    SemanticSearch,
    SearchIndex
)
from azure.search.documents.models import VectorizedQuery

from .prompt_content_db import nonewlines, PromptContentDB, VECTOR_FIELD_NAME
from vi_search.utils.azure_utils import get_azd_env_values


logger = logging.getLogger(__name__)


class AzureVectorSearch(PromptContentDB):
    def __init__(self) -> None:
        super().__init__()
        self._search_params = self._get_search_params()
        self._index_client = SearchIndexClient(**self._search_params)

    @staticmethod
    def _get_search_params() -> dict:
        azd_env_values = get_azd_env_values()
        tenantid = azd_env_values["AZURE_TENANT_ID"]
        searchkey = azd_env_values["AZURE_SEARCH_KEY"]
        azure_search_service = azd_env_values["AZURE_SEARCH_SERVICE"]

        # Use the current user identity to connect to Azure services unless a key is explicitly set for any of them
        azd_credential = AzureDeveloperCliCredential() if tenantid == None else AzureDeveloperCliCredential(
            tenant_id=tenantid, process_timeout=60)
        default_creds = azd_credential if searchkey == None else None
        search_creds = default_creds if searchkey == None else AzureKeyCredential(searchkey)

        search_params = {
            "endpoint": f"https://{azure_search_service}.search.windows.net/",
            "credential": search_creds
        }

        return search_params

    def _get_search_client(self, index_name) -> SearchClient:
        search_client = SearchClient(**self._search_params, index_name=index_name)
        return search_client

    def create_db(self, name: str, vector_search_dimensions: int) -> None:
        ''' Create new or get existing Azure Search index.

        :param name: The name of the index
        :param vector_search_dimensions: The number of dimensions of the embeddings
        '''
        search_client = self.create_new_search_index(name, vector_search_dimensions)
        self.db_name = name
        self.db_handle = search_client

    def remove_db(self, name: str) -> None:
        ''' Removes index.

        :param name: The name of the index
        '''

        video_id = None  # The functional actually supports removing sections by video_id, but we don't use it
        logger.info(f"Removing sections from '{video_id or '<all>'}' from search index '{name}'")

        search_client = self._get_search_client(name)

        total_count = 0
        while True:
            filter_ = None if video_id == None else f"video_id eq '{video_id}'"
            r = search_client.search("", filter=filter_, top=1000, include_total_count=True)
            if r.get_count() == 0:
                break

            r = search_client.delete_documents(documents=[{"id": d["id"]} for d in r])
            logger.info(f"\tRemoved {len(r)} sections from index")

            total_count += len(r)

            # It can take a few seconds for search results to reflect changes, so wait a bit
            time.sleep(2)

        logger.info(f"Done removing sections from index. Total removed: {total_count}")

    def get_available_dbs(self) -> list[str]:
        ''' Get the list of available search indexes. '''
        indexes = self._index_client.list_index_names()
        indexes = [index for index in indexes]
        return indexes

    def set_db(self, name: str) -> None:
        if name not in self.get_available_dbs():
            raise RuntimeError(f"Search index {name} does not exists")

        search_client = self._get_search_client(name)
        self.db_name = name
        self.db_handle = search_client

    def add_entry_batch(self, entry_batch):
        ''' Add entry batch to the index.

        :param entry_batch: List of entries to be added to the index
        '''

        results = self.db_handle.upload_documents(documents=entry_batch)
        succeeded = sum([1 for r in results if r.succeeded])

        # TODO: Add a retry mechanism for failed uploads, fail the entire batch if more than 20% failed
        if succeeded < len(results):
            logger.warning(f"\tIndexed {len(results)} sections, {succeeded} succeeded")
        else:
            logger.info(f"\tIndexed {len(results)} sections, {succeeded} succeeded")

    def vector_search(self, embeddings_vector, n_results=3, exhaustive_search=False) -> tuple[dict, list[str]]:
        ''' Query the collection with the given embeddings vector.

        :param embeddings_vector: embeddings vector to search in the collection
        :param n_results: Number of results to return
        :param exhaustive_search: When true, triggers an exhaustive k-nearest neighbor search across all
            vectors within the vector index. Useful for scenarios where exact matches are critical, such as
            determining ground truth values.
        '''
        vector_query = VectorizedQuery(vector=embeddings_vector, k_nearest_neighbors=n_results,
                                       fields=VECTOR_FIELD_NAME, exhaustive=exhaustive_search)

        results = self.db_handle.search(search_text=None, vector_queries=[vector_query])
        results = list(results)

        docs_by_id = {doc["id"]: doc for doc in results}
        results_content = [f'{doc["id"]}: {nonewlines(doc["content"])}' for doc in results]

        return docs_by_id, results_content

    def create_new_search_index(self, name, vector_search_dimensions: int = 1536, verify_new=False) -> SearchClient:
        ''' Create a new search index in Azure Cognitive Search if it doesn't already exist. '''

        if name in self.get_available_dbs():
            if verify_new:
                raise RuntimeError(f"Search index {name} already exists")

            logger.info(f"Getting existing Search Index {name}...")
            search_client = self._get_search_client(name)
            return search_client

        logger.info(f"Creating new Search Index {name}...")

        str_metadata_properties = dict(type=SearchFieldDataType.String, filterable=True, facetable=True,
                                       retrievable=True, searchable=True)
        int_metadata_properties = dict(type=SearchFieldDataType.Int32, filterable=True, facetable=True,
                                       retrievable=True, searchable=True)

        # TODO: Notice there is some duplicated data. Consider improving by multiple tables.

        VECTOR_SEARCH_CONFIG = "my_vector_search_config"
        fields = [
            SimpleField(name="id", type=SearchFieldDataType.String, key=True),
            SimpleField(name="account_id", **str_metadata_properties),
            SimpleField(name="location", **str_metadata_properties),
            SimpleField(name="video_id", **str_metadata_properties),
            SimpleField(name="partition", **str_metadata_properties),
            SimpleField(name="video_name", **str_metadata_properties),
            SimpleField(name="section_idx", **int_metadata_properties),
            SimpleField(name="start_time", **str_metadata_properties),
            SimpleField(name="end_time", **str_metadata_properties),
            SearchableField(name="content", type=SearchFieldDataType.String, retrievable=True, searchable=True),
            SearchField(name=VECTOR_FIELD_NAME,
                        type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
                        searchable=True,
                        vector_search_dimensions=vector_search_dimensions,
                        vector_search_profile_name=VECTOR_SEARCH_CONFIG)
            ]

        # Configure the vector search configuration
        vector_search = VectorSearch(
            algorithms=[
                HnswAlgorithmConfiguration(
                    name="myHnsw"
                )
            ],
            profiles=[
                VectorSearchProfile(
                    name=VECTOR_SEARCH_CONFIG,
                    algorithm_configuration_name="myHnsw",
                )
            ]
        )

        semantic_config = SemanticConfiguration(
            name="my-semantic-config",
            prioritized_fields=SemanticPrioritizedFields(
                # title_field=SemanticField(field_name="title"),
                # keywords_fields=[SemanticField(field_name="category")],
                content_fields=[SemanticField(field_name="content")]
            )
        )

        # Create the semantic settings with the configuration
        semantic_search = SemanticSearch(configurations=[semantic_config])

        # Create the search index with the semantic settings
        index = SearchIndex(name=name, fields=fields, vector_search=vector_search, semantic_search=semantic_search)

        self._index_client.create_index(index)
        search_client = self._get_search_client(name)
        return search_client


    def get_index_data(self, filters: Optional[str] = None, search_fields: Optional[list[str]] = None,
                       top: Optional[int] = None):
        ''' Returns Index data.

        :param filters: Filter to apply to the search. Filter example: "video_id eq '1'"
        :param search_fields: List of fields to search in. Example: ["video_id", "content"]
        :param top: Number of results to return
        '''
        logger.info(f"Index `{self.db_name}` document_count is: {self.db_handle.get_document_count()}")

        results = self.db_handle.search(search_text="*", filter=filters, search_fields=search_fields, top=top,
                                        include_total_count=True)

        # Sanity check for full index retrieval
        if filters is None and top is None:
            # This is less efficient but needed for the count. Keep it until we are sure the count is valid.
            results = list(results)
            if len(results) != self.db_handle.get_document_count():
                raise RuntimeError("The count of the results is not equal to the count of the documents in the index")

        return results
