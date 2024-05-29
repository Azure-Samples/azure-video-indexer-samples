import logging
import os

from flask import Flask, request, jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

from vi_search.ask import RetrieveThenReadVectorApproach


search_db = os.environ.get("PROMPT_CONTENT_DB", "azure_search")
if search_db == "chromadb":
    from vi_search.prompt_content_db.chroma_db import ChromaDB
    prompt_content_db = ChromaDB()
elif search_db == "azure_search":
    from vi_search.prompt_content_db.azure_search import AzureVectorSearch
    prompt_content_db = AzureVectorSearch()
else:
    raise ValueError(f"Unknown search_db: {search_db}")

lang_model = os.environ.get("LANGUAGE_MODEL", "openai")
if lang_model == "openai":
    from vi_search.language_models.azure_openai import OpenAI
    language_models = OpenAI()
elif lang_model == "dummy":
    from vi_search.language_models.dummy_lm import DummyLanguageModels
    language_models = DummyLanguageModels()
else:
    raise ValueError(f"Unknown language model: {lang_model}")


ask_approaches = {
    "rrrv": RetrieveThenReadVectorApproach(prompt_content_db=prompt_content_db, language_models=language_models)
}

app = Flask(__name__)

# The limiter is used to prevent abuse of the API, you can adjust the limits as needed
limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["300000 per day", "20000 per hour"],
    storage_uri="memory://",
)
ASK_RATE_LIMIT_PER_DAY = 1000
ASK_RATE_LIMIT_PER_MIN = 50


@app.route("/", defaults={"path": "index.html"})
@app.route("/<path:path>")
def static_file(path):
    return app.send_static_file(path)


@app.route("/ask", methods=["POST"])
@limiter.limit(f"{ASK_RATE_LIMIT_PER_DAY}/day;{ASK_RATE_LIMIT_PER_MIN}/minute", override_defaults=True)
def ask():
    approach = request.json["approach"]
    try:
        impl = ask_approaches.get(approach)
        if impl is None:
            return jsonify({"error": "unknown approach"}), 400

        # print(f"question: {request.json['question']}")
        r = impl.run(request.json["question"], request.json.get("overrides") or {})
        print(f"response: {r['answer']}\n\n")
        # print(f"response: {r}\n\n")
        return jsonify(r)

    except Exception as e:
        logging.exception("Exception in /ask")
        return jsonify({"error": str(e)}), 500


@app.route("/indexes", methods=["GET"])
def get_indexes():
    indexes = prompt_content_db.get_available_dbs()

    return jsonify(indexes)

# Handle the rate limit exceeded exception
@app.errorhandler(429)
def ratelimit_handler(e):
    return jsonify({"error": "Rate limit: Exceeded the number of asks per day", "message": e.description}), 429


if __name__ == "__main__":
    app.run()
