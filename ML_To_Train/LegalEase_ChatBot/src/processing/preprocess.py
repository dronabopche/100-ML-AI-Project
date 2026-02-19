import re
from typing import List

def clean_text(text: str) -> str:
    text = text.strip()
    text = re.sub(r"\s+", " ", text)
    return text


def tokenize(text: str) -> List[str]:
    # Simple tokenizer (you can replace with HuggingFace tokenizer later)
    return text.split(" ")


def preprocess_prompt(prompt: str) -> List[str]:
    cleaned = clean_text(prompt)
    tokens = tokenize(cleaned)
    return tokens
