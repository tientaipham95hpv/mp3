import sys
import os

# Add backend directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from main import app

# Vercel Serverless Function Entrypoint v1.2.2 - Storyboard JPG image filter for 100% MP3 audio downloads
