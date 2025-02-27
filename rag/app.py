from flask import Flask, request, jsonify
from langchain_groq import ChatGroq
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
import os

app = Flask(__name__)

# Load API key for Groq LLM
GROQ_API_KEY = os.getenv("GROQ_API_KEY")

if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY is not set. Check your environment variables or .env file.")

# Initialize LLM
llm = ChatGroq(
    model="llama-3.3-70b-versatile",
    api_key=GROQ_API_KEY,
    temperature=0,
    streaming=True
)

# Load saved ChromaDB embeddings
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")
vector_store = Chroma(persist_directory="./chroma_db", embedding_function=embeddings)

# API endpoint to handle user queries
@app.route("/chat", methods=["POST"])

def chat():
    print('Hit route')  
    data = request.json
    user_question = data.get("question", "")

    if not user_question:
        return jsonify({"error": "Question is required"}), 400

    # Perform similarity search
    retrieved_docs = vector_store.similarity_search(user_question, k=3)
    context = "\n".join([doc.page_content for doc in retrieved_docs])

    # Construct prompt
    prompt = f"""
    You are an assistant for powerlifting. Answer questions using the context below.
    If you don't know, just say you don't know, while providing answer give in bullet points.
    
    Context:
    {context}

    Question: {user_question}
    Answer:
    """

    response = llm.invoke(prompt).content
    return jsonify({"response": response})

if __name__ == "__main__":
    app.run(debug=True)