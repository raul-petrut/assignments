import json
from pathlib import Path

from app.rag.chroma_client import get_collection
from app.rag.embedder import embed_texts
from app.models.book_schemas import Book

DATA_PATH = Path("data/book_summaries.json")

def load_books() -> list[dict]:
    with DATA_PATH.open("r", encoding="utf-8") as books_data_file:
        return json.load(books_data_file)

# index a single book
def index_book(book: Book) -> None:
    chromadb_collection = get_collection()

    title_id = book.title.lower().replace(" ", "_")
    short_summary = book.short_summary
    metadata = {
        "title": book.title,
        "author": book.author,
        "themes": ", ".join(book.themes)
    }
    embedding = embed_texts([short_summary])[0]

    chromadb_collection.upsert(ids=[title_id], documents=[short_summary], metadatas=[metadata], embeddings=[embedding])

    # insert the book into the DATA_PATH file as well to ensure it's available for future retrievals
    books = load_books()
    books.append(book.model_dump())
    with DATA_PATH.open("w", encoding="utf-8") as books_data_file:
        json.dump(books, books_data_file, ensure_ascii=False, indent=2)

# index all books from the data file
def index_books() -> None:
    books = load_books()
    chromadb_collection = get_collection()

    titles = [book["title"].lower().replace(" ", "_") for book in books]
    short_summaries = [book["short_summary"] for book in books]
    metadatas = [
        {
            "title": book["title"],
            "author": book["author"],
            "themes": ", ".join(book["themes"])
        }
        for book in books
    ]
    embeddings = embed_texts(short_summaries)

    chromadb_collection.upsert(ids=titles, documents=short_summaries, metadatas=metadatas, embeddings=embeddings)

    print(f"Indexed {len(books)} books into ChromaDB")

if __name__ == "__main__":
    index_books()