from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain.agents import initialize_agent, Tool
from langchain.agents.agent_types import AgentType

load_dotenv()

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

def groq_info(query: str) -> str:
    return "Groq uses a deterministic dataflow architecture optimized for ultra-low latency inference."

tools = [
    Tool(
        name="GroqInfo",
        func=groq_info,
        description="Provides information about Groq architecture"
    )
]

agent = initialize_agent(
    tools,
    llm,
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True
)

response = agent.run("Explain Groq architecture performance advantages")

print(response)