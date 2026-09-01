import sys
import os

# Add backend directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from main import app

# Vercel Serverless Function Entrypoint v1.1.8 - Remote EJS GitHub challenge solver for 24/7 cloud extraction
