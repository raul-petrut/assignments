from app.core.config import get_settings
from app.models.book_schemas import RetrievedBook
from app.rag.chroma_client import get_collection
from app.rag.embedder import embed_texts

settings = get_settings()


def semantic_search(query: str, top_k: int | None = None) -> list[RetrievedBook]:
    chromadb_collection = get_collection()
    embedding = embed_texts([query])[0]
    result = chromadb_collection.query(query_embeddings=[embedding], n_results=top_k or settings.top_k)

    # default to an empty list of lists in case of not finding a match to the query
    # this prevents a Key/Index Error
    documents = result.get("documents", [[]])[0]
    metadatas = result.get("metadatas", [[]])[0]
    distances = result.get("distances", [[]])[0]

    items: list[RetrievedBook] = list()
    
    for doc, meta, distance in zip(documents, metadatas, distances):
        raw_themes = meta.get("themes", []) if isinstance(meta, dict) else []
        if isinstance(raw_themes, str):
            themes = [t.strip() for t in raw_themes.split(",") if t.strip()]
        elif isinstance(raw_themes, list):
            themes = raw_themes
        else:
            themes = []

        items.append(RetrievedBook(
            title=meta.get("title", "Unknown") if isinstance(meta, dict) else "Unknown",
            author=meta.get("author", "Unknown") if isinstance(meta, dict) else "Unknown",
            short_summary=doc,
            themes=themes,
            score=distance
        ))
    return items