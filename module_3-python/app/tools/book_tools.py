import json
from pathlib import Path

DATA_PATH = Path("data/book_summaries.json")

def _load_books() -> list[dict]:
    with DATA_PATH.open("r", encoding="utf-8") as book_summaries_file:
        return json.load(book_summaries_file)
    
def get_summary_by_title(title: str) -> str:
    books = _load_books()
    for book in books:
        if book["title"].strip().lower() == title.strip().lower():
            return book["full_summary"]
        
    return "Summary not found for the requested title."