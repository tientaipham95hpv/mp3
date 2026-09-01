import sys
import os

# Add backend directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from main import app

# Vercel Serverless Function Entrypoint v1.1.0 - android/ios client & ba/b format fix for music video download
