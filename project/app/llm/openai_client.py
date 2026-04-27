from openai import OpenAI
from app.core.config import get_settings


_settings = get_settings()

def get_openai_client() -> OpenAI:
    return OpenAI(api_key=_settings.openai_api_key)
