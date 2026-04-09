from typing import List
from pydantic import BaseModel, Field
from enum import Enum

class Book(BaseModel):
    title: str
    author: str
    themes: List[str] = Field(default_factory=list)
    short_summary: str
    full_summary: str

class RetrievedBook(BaseModel):
    title: str
    author: str
    short_summary: str
    themes: List[str] = Field(default_factory=list)
    score: float | None = None

class WebSearchResponse(BaseModel):
    source_url: str = Field(description="URL of the web page where the information was retrieved")
    generated_summary: str = Field(description="Detailed summary generated from the web search results")
    author: str = Field(description="Author of the recommended book")

class RecommendationResponse(BaseModel):
    recommended_title: str = Field(description="Exact title of the recommended book")
    reason: str = Field(description="Why the book fits the user's request")
    themes: List[str] = Field(default_factory=list, description="Themes of the recommended book")
    follow_up_question: str | None = None
    web_search_response: WebSearchResponse | None = None


class ChatResultResponseType(Enum):
    SUCCESSFUL = "SUCCESSFUL"
    WEB_SEARCH = "WEB_SEARCH"
    PROFANITY_DETECTED = "PROFANITY_DETECTED"
    NO_RECOMMENDATION = "NO_RECOMMENDATION"

class ChatResult(BaseModel):
    recommendation: RecommendationResponse
    detailed_summary: str | None = None
    retrieved_context: List[RetrievedBook] = Field(default_factory=list)
    response_type: ChatResultResponseType  = Field(description="Type of the response")