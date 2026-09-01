import sys
import os

# Add backend directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from main import app

if __name__ == "__main__":
    import uvicorn
    # Hugging Face Spaces free tier listens on port 7860
    uvicorn.run(app, host="0.0.0.0", port=7860)
