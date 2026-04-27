import chromadb
from chromadb.api.models.Collection import Collection
from app.core.config import get_settings


settings = get_settings()
# _client = chromadb.PersistentClient(path=settings.chroma_path)

def get_collection() -> Collection:
    pass
    #    return _client.get_or_create_collection(name=settings.chroma_collection)
