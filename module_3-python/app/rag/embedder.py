from app.core.config import get_settings
from app.llm.openai_client import get_openai_client

settings = get_settings()

def embed_texts(texts: list[str]) -> list[list[float]]:
    openai_client = get_openai_client()
    response = openai_client.embeddings.create(
        model=settings.openai_embedding_model,
        input=texts
    )
    return [item.embedding for item in response.data]