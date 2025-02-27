from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
import pymupdf4llm
import os

# Load and convert Powerlifting document to text
docs = pymupdf4llm.to_markdown("./books/guide.pdf")

# Initialize Text Splitter
from langchain_text_splitters import RecursiveCharacterTextSplitter

text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
chunks = text_splitter.split_text(docs)

# Convert to LangChain document format
from langchain_core.documents import Document
documents = [Document(page_content=chunk) for chunk in chunks]

# Initialize Embedding Model
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")

# Store in ChromaDB
os.makedirs("chroma_db", exist_ok=True)
vector_store = Chroma(persist_directory="chroma_db", embedding_function=embeddings)
vector_store.add_documents(documents)
vector_store.persist()

print("✅ Powerlifting document processed & stored in ChromaDB!")