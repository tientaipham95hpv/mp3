import sys
import os

# Add backend directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from main import app

# Vercel Serverless Function Entrypoint v1.1.7 - Unrestricted android_vr/android player_client extraction fix
