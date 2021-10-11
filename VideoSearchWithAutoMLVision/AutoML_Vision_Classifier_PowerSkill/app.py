import os
from typing import Dict, List

import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI, Security, Depends, HTTPException
from fastapi.security.api_key import APIKeyHeader, APIKey
from pydantic import BaseModel
from starlette.status import HTTP_403_FORBIDDEN

from powerskill import extractor, models, vi
import logging

load_dotenv()
app = FastAPI()


class Values(BaseModel):
    values: List = []


class Value(Values):
    recordId: str
    data: Dict[str, str] = None


API_KEY = os.environ['KEY']
API_KEY_NAME = "Ocp-Apim-Subscription-Key"

api_key_header = APIKeyHeader(name=API_KEY_NAME, auto_error=False)
class_model = models.Models(azureml_model_dir=None, classication_model=None)
video_indexer_api = vi.VideoIndexerAPI(vi_api_key=os.environ['VI_API_KEY'],
                                       vi_location=os.environ['VI_LOCATION'],
                                       vi_account_id=os.environ['VI_ACCOUNT_ID'])


@app.on_event("startup")
async def startup_event():
    try:
        if os.environ['GET_LATEST_MODEL'].lower() == "true":
            logging.info(f"Download latest model")
            if class_model.get_latest_model(os.environ['EXPERIMENT_NAME']):
                class_model.load_classification_model('models/train_artifacts/')
            else:
                class_model.load_classification_model(os.environ['AZUREML_MODEL_DIR'])
        else:
            class_model.load_classification_model(os.environ['AZUREML_MODEL_DIR'])
    except Exception as NOMODELFOUND:
        logging.error(f"No model could be loaded {NOMODELFOUND}")


async def get_api_key(
        api_key_header: str = Security(api_key_header),
):
    if api_key_header == API_KEY:
        return api_key_header
    else:
        raise HTTPException(
            status_code=HTTP_403_FORBIDDEN, detail="Key not present"
        )


@app.get('/api/healthcheck', status_code=200)
async def healthcheck():
    return 'Ready'


@app.post('/api/extraction')
def extract(values: Values, api_key: APIKey = Depends(get_api_key)):
    body = values.dict()
    if not body:
        return 'Expected text within body of request. No text found.', status.HTTP_400_BAD_REQUEST
    else:
        return extractor.go_extract(body, classification_model=class_model.classication_model,
                                    video_indexer=video_indexer_api)


# Remove these two lines below for non-debug/production mode
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
