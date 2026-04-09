from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    openai_api_key: str = Field(alias="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-5-mini", alias="OPENAI_MODEL")
    openai_embedding_model: str = Field(
        default="text-embedding-3-small", alias="OPENAI_EMBEDDING_MODEL"
    )
    chroma_path: str = Field(default="./chroma", alias="CHROMA_PATH")
    chroma_collection: str = Field(default="book_summaries", alias="CHROMA_COLLECTION")
    
    # Number of top similar books to retrieve from ChromaDB
    top_k: int = Field(default=3, alias="TOP_K")


def get_settings() -> Settings:
    return Settings()
