from google import genai
import os

# Get API key from environment variable
os.environ["GOOGLE_API_KEY"] = "bfhjScuFkbkjkKFlnfkvinKbjokpo-bfiafnksbfa-fkh"
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

PROMPT = """
Create a simple Dockerfile for {language}.
Include:
- Base image
- Install dependencies
- Set working directory
- Copy application files
- Run the application
Only return the Dockerfile.
"""


def generate_dockerfile(language):
    chat = client.chats.create(
        model="gemini-3.8-flash"
    )

    response = chat.send_message(
        PROMPT.format(language=language)
    )

    return response.text


if __name__ == "__main__":
    language = input("Enter the programming language: ")

    dockerfile = generate_dockerfile(language)

    print("\nGenerated Dockerfile:\n")
    print(dockerfile)
