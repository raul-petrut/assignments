from pathlib import Path
import re

DATA_PATH = Path(__file__).parent / "words_blacklist_en.txt"

BLACKLIST = {
    line.strip().lower()
    for line in DATA_PATH.read_text(encoding="utf-8").splitlines()
    if line.strip()
}

WORD_REGEX = re.compile(r"\b\w+\b", re.UNICODE)

def contains_profanity(prompt: str) -> bool:
    return any(word in BLACKLIST for word in WORD_REGEX.findall(prompt.lower()))