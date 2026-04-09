import json
from typing import Any
from app.services.cag_service import _CONVERSATION_MEMORY, _format_assistant_memory_entry

from app.core.config import get_settings
from app.llm.openai_client import get_openai_client
from app.models.book_schemas import ChatResult, RecommendationResponse, ChatResultResponseType, RetrievedBook, Book
from app.rag.retriever import semantic_search
from app.services.moderation import contains_profanity
from app.tools.book_tools import get_summary_by_title
from app.rag.index_books import index_book

settings = get_settings()

SYSTEM_PROMPT = """
    # Identity:  
    You are a helpful and knowledgeable assistant specializing in book recommendations and summaries.  
    
    # Purpose:  
    Your primary goal is to assist users in finding books that match
    their interests and providing concise summaries of those books.
    Always first answer in text format respecting the RecommendationResponse schema.
    
    # Always follow these guidelines when answering:

    ## Context Usage:
    - Always start by analyzing the retrieved book context provided to you.
    - Recommend exactly one book.
    - Never recommend books that are not in the retrieved context.
    - Recommend a book only if it is a good match for the user's query based on the retrieved context.
    - Never include a follow-up question if there is a good recommendation to make.
    
    ## Web Search Fallback:
    - If and only if there is no good recommendation to make based on the retrieved context,
    use the web_search tool to find more information about a book that is a good match for the user's query.
    - Use the web_search tool before concluding that there is no good recommendation to make.
    - Always generate a detailed summary of the recommended book based on the web search results, as they are more up-to-date and relevant in this scenario.
    - Include a hyprlink to the source of the information when using the web_search tool.
    - Never include context from the retrieved books if you use the web_search tool, as the web search results are more up-to-date and relevant in this scenario.
    - Never include a follow-up question if there is a good recommendation to make.
    
    ## No Recommendation Scenario:
    - If no good recommendation can be made based on the retrieved context and web_search tool, do not recommend any book
    - Ask a follow-up question to clarify the user's interests.
    - Only include a follow-up question if there is no good recommendation to make.
""".strip()

def _build_context(retrieved: list[RetrievedBook]) -> str:
    lines: list[str] = []
    for item in retrieved:
        themes = ", ".join(item.themes) if item.themes else "-"
        lines.append(
            f"Title: {item.title}\n\
                Author: {item.author}\n\
                Short summary: {item.short_summary}\n\
                Themes: {themes}\n\
                Score: {item.score}"
        )
    return "\n\n".join(lines)

def _tool_schema() -> list[dict[str, Any]]:
    return [{
        "type": "web_search",
        "filters": {
            "allowed_domains": [
                "openlibrary.org",
                "books.google.com"
            ],
        }
    }]

def _get_no_recommendation_response() -> ChatResult:
    fallback = RecommendationResponse(
        recommended_title="",
        reason="No suitable books were found for this request.",
        themes=[],
        follow_up_question="Would you like to try a different topic?",
    )
    return ChatResult(
        recommendation=fallback,
        detailed_summary="",
        retrieved_context=[],
        response_type=ChatResultResponseType.NO_RECOMMENDATION,
    )

def _get_profanity_response() -> ChatResult:
    response = RecommendationResponse(
        recommended_title="",
        reason="Please refrain from using inapropriate language.",
        themes=[],
        follow_up_question="What type of book would you like?"
    )
    return ChatResult(
        recommendation=response,
        detailed_summary="",
        retrieved_context=[],
        response_type=ChatResultResponseType.PROFANITY_DETECTED
    )

def answer_user(query: str) -> ChatResult:

    if contains_profanity(query):
        return _get_profanity_response()

    retrieved_books = semantic_search(query)

    if not retrieved_books:
        response = _get_no_recommendation_response()
        _CONVERSATION_MEMORY.append((
            query,
            _format_assistant_memory_entry(response.recommendation)
        ))
        return response

    context = _build_context(retrieved_books)

    messages: list[dict[str, str]] = [{"role": "system", "content": SYSTEM_PROMPT}]
    for prev_user, prev_assistant in _CONVERSATION_MEMORY:
        messages.append({"role": "user", "content": prev_user})
        messages.append({"role": "assistant", "content": prev_assistant})
    messages.append({
        "role": "user",
        "content": f"Context:\n{context}\n\nUser query: {query}"
    })

    openai_client = get_openai_client()

    response = openai_client.responses.parse(
        model=settings.openai_model,
        input=messages,
        text_format=RecommendationResponse,
        tools=_tool_schema()
    )

    # If the model doesn't recommend a book but provides a follow-up question, return that to the user
    if response.output_parsed.follow_up_question and not response.output_parsed.recommended_title:

        chat_result = ChatResult(
            recommendation=RecommendationResponse(
                recommended_title="",
                reason=response.output_parsed.reason,
                themes=[],
                follow_up_question=response.output_parsed.follow_up_question
            ),
            detailed_summary="",
            retrieved_context=retrieved_books,
            response_type=ChatResultResponseType.NO_RECOMMENDATION
        )

        _CONVERSATION_MEMORY.append((
            query,
            _format_assistant_memory_entry(chat_result.recommendation)
        ))

        return chat_result

    if response.output_parsed.web_search_response:

        # generate a concise summary based on the detailed summary generated from the web search results
        # used to populate the book index
        short_summary = openai_client.responses.create(
            model=settings.openai_model,
            input=[
                { "role": "system", "content": "You are a helpful assistant that generates short and concise summaries of books based on detailed information about them." },
                { "role": "user", "content": f"Generate a concise summary for a book with the following details:\n\n{response.output_parsed.web_search_response.generated_summary}" }
            ]
        )

        web_search_book: Book = Book(
            title=response.output_parsed.recommended_title,
            author=response.output_parsed.web_search_response.author,
            themes=response.output_parsed.themes,
            short_summary=short_summary.output_text,
            full_summary=response.output_parsed.web_search_response.generated_summary
        )
        index_book(web_search_book)

        reccomendation = RecommendationResponse(
            recommended_title=web_search_book.title,
            reason=response.output_parsed.reason,
            themes=web_search_book.themes,
            follow_up_question=None
        )
        return ChatResult(
            recommendation=reccomendation,
            detailed_summary=web_search_book.full_summary,
            retrieved_context=retrieved_books,
            response_type=ChatResultResponseType.WEB_SEARCH
        )

    summary = get_summary_by_title(response.output_parsed.recommended_title)

    recommendation = RecommendationResponse(
        recommended_title=response.output_parsed.recommended_title,
        reason=response.output_parsed.reason,
        themes=response.output_parsed.themes,
        follow_up_question=None
    )

    _CONVERSATION_MEMORY.append((
        query,
        _format_assistant_memory_entry(recommendation)
    ))

    return ChatResult(
        recommendation=recommendation,
        detailed_summary=summary,
        retrieved_context=retrieved_books,
        response_type=ChatResultResponseType.SUCCESSFUL
    )
