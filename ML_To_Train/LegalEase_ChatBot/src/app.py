from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from processing.preprocess import preprocess_prompt
from output.model import generate_output

app = FastAPI(title="Prompt Inference API")


class PromptRequest(BaseModel):
    prompt: str


class PromptResponse(BaseModel):
    prompt: str
    output: str


@app.get("/")
def health_check():
    return {"status": "ok"}


@app.post("/generate", response_model=PromptResponse)
def generate(req: PromptRequest):
    prompt = req.prompt.strip()

    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")

    tokens = preprocess_prompt(prompt)
    output = generate_output(tokens)

    return {"prompt": prompt, "output": output}
