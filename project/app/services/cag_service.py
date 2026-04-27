from collections import deque
from typing import Deque, List, Tuple
from app.models.book_schemas import RecommendationResponse

# Keep the last 5 (user, assistant) conversational turns in-memory
# Stored as tuples: (user_query, assistant_brief_response)
_CONVERSATION_MEMORY: Deque[Tuple[str, str]] = deque(maxlen=5)

def get_conversation_memory() -> List[Tuple[str, str]]:
    return list(_CONVERSATION_MEMORY)

def reset_conversation_memory() -> None:
    _CONVERSATION_MEMORY.clear()

def _format_assistant_memory_entry(recommendation: RecommendationResponse) -> str:
    themes = ", ".join(recommendation.themes) if recommendation.themes else "-"
    follow_up = recommendation.follow_up_question or ""
    return (
        f"Recommended: {recommendation.recommended_title}\n"
        f"Reason: {recommendation.reason}\n"
        f"Themes: {themes}\n"
        f"Follow-up: {follow_up}"
    )