from PyPDF2 import PdfReader
import csv

# Define file paths
pdf_path = "20240213062038ab.pdf"
csv_path = "20240213062038ab.csv"

# Read PDF
reader = PdfReader(pdf_path)
text_data = [page.extract_text() for page in reader.pages]

# Write data to CSV
with open(csv_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    for page_text in text_data:
        for line in page_text.splitlines():
            writer.writerow(line.split())