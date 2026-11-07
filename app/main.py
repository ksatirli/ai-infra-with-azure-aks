"""Chat API that calls IBM Granite on Microsoft Foundry managed compute.

There is no API key. On AKS, the workload identity webhook injects
AZURE_CLIENT_ID, AZURE_TENANT_ID and AZURE_FEDERATED_TOKEN_FILE into the pod,
and DefaultAzureCredential exchanges the projected service account token for an
Entra ID token. Foundry serves the Granite deployment behind its OpenAI-compatible
v1 API, where the model field is the deployment name.
"""

import os

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from fastapi import FastAPI
from openai import OpenAI
from pydantic import BaseModel, Field

BASE_URL = os.environ["FOUNDRY_BASE_URL"]
DEPLOYMENT = os.environ["FOUNDRY_DEPLOYMENT"]
TOKEN_SCOPE = os.environ.get("FOUNDRY_TOKEN_SCOPE", "https://cognitiveservices.azure.com/.default")

# A callable api_key is called per request, so tokens refresh on their own.
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
