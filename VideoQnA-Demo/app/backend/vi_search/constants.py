from pathlib import Path


ALGO_VERSION = '0.1.0'
SCHEMA_VERSION = '0.0.1'

BACKEND_DIR = Path(__file__).parent.parent.absolute().resolve()
BASE_DIR = BACKEND_DIR.parent.parent.absolute().resolve()

DATA_DIR = BASE_DIR / 'data'

CHROMA_DB_DIR = BACKEND_DIR / '.chroma'
