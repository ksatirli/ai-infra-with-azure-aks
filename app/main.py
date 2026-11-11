"""Chat API that calls IBM Granite on Microsoft Foundry managed compute."""

import os

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from fastapi import FastAPI
from openai import OpenAI
from pydantic import BaseModel, Field

BASE_URL = os.environ["FOUNDRY_BASE_URL"]
DEPLOYMENT = os.environ["FOUNDRY_DEPLOYMENT"]
TOKEN_SCOPE = os.environ.get("FOUNDRY_TOKEN_SCOPE", "https://cognitiveservices.azure.com/.default")

client = OpenAI(
    base_url=BASE_URL,
    api_key=get_bearer_token_provider(DefaultAzureCredential(), TOKEN_SCOPE),
)

app = FastAPI(title="chat-api")


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)


class ChatResponse(BaseModel):
    reply: str
    model: str


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/chat")
def chat(request: ChatRequest) -> ChatResponse:
    completion = client.chat.completions.create(
        model=DEPLOYMENT,
        messages=[
            {"role": "system", "content": "You are a concise assistant. Answer in two sentences or fewer."},
            {"role": "user", "content": request.message},
        ],
        max_tokens=200,
    )
    return ChatResponse(reply=completion.choices[0].message.content or "", model=completion.model)
