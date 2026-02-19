from typing import List

# This is a placeholder.
# Replace this with your real ML model loading code (HuggingFace, sklearn, etc.)

_MODEL = None


def load_model():
    global _MODEL

    if _MODEL is None:
        # Load model only once (important for performance)
        _MODEL = "../../models/LegalQA.pkl"

    return _MODEL


def generate_output(tokens: List[str]) -> str:
    model = load_model()

    # Dummy inference (replace with real model.predict or model.generate)
    # Example output:
    return f"[MODEL={model}] Output based on tokens: {' '.join(tokens)}"
