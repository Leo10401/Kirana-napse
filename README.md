Kirana-Napse: AI-Powered Inventory Management for Kirana Stores

Kirana-Napse is an intelligent inventory management application designed specifically for kirana stores in India. It uses AI-powered demand forecasting and automation to help shopkeepers optimize stock, reduce waste, and improve profitability.

Key Features
AI-Powered Demand Forecasting
Accurate predictions based on historical data
Identifies demand patterns (daily, weekly, festival surges)
Reduces overstocking and stockouts
Automated Reorder Suggestions
When stock hits reorder level
Suggests optimal quantity
Generates purchase orders
Multi-Vendor Procurement
Finds best prices from multiple suppliers
Calculates landed cost (including taxes, transport)
Enables competitive sourcing
Smart Inventory Management
Real-time stock tracking
Expiry date monitoring
Batch tracking for FMCG
Analytics Dashboard
Sales trends
Profit margins
Popular items
Low-stock alerts
Notifications & Reminders
WhatsApp-style messages for orders
Reorder alerts
Payment reminders

Tech Stack
Backend

Framework: FastAPI (Python)
Database: MongoDB
Authentication: JWT
Notifications: Firebase Cloud Messaging (FCM)
Deployment: Render (Global)
Mobile App

Framework: Flutter
State Management: Provider
Networking: Dio
Local Storage: Hive
Notifications: Firebase Cloud Messaging (FCM)
Deployment: Firebase Hosting (Global)

Getting Started
Prerequisites

Python 3.11+
Node.js 16+
Flutter 3.12+
MongoDB Atlas account
Firebase project

Installation
Backend

# Clone the repository
git clone <repository-url>
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn main:app --reload --host [IP_ADDRESS] --port 8000

Mobile App

# Clone the repository
git clone <repository-url>
cd kirananapse

# Install dependencies
pub get

# Run the app
flutter run

Project Structure
backend/
├── main.py          # FastAPI app entry point
├── api/             # API routes
│   ├── auth.py      # Authentication
│   ├── stock.py     # Stock management
│   ├── orders.py    # Order management
│   └── products.py  # Product management
├── models/          # MongoDB models
├── services/        # Business logic
├── utils/           # Utilities
└── firebase-credentials.json

kirananapse/
├── lib/
│   ├── main.dart          # App entry point
│   ├── providers/         # State management
│   │   ├── auth_provider.dart
│   │   ├── stock_provider.dart
│   │   └── order_provider.dart
│   ├── screens/           # UI screens
│   │   ├── auth/login_screen.dart
│   │   ├── home/dashboard_screen.dart
│   │   ├── inventory/stock_list_screen.dart
│   │   ├── orders/order_screen.dart
│   │   └── settings/settings_screen.dart
│   ├── widgets/           # Reusable widgets
│   ├── services/          # API services
│   ├── utils/             # Utility functions
│   └── models/            # Data models
├── pubspec.yaml
└── README.md


Configuration
Backend

Copy .env.example to .env and fill in your MongoDB connection string and other credentials:

# MongoDB Connection
MONGODB_URL=mongodb+srv://<username>:<password>@<cluster-url>/?retryWrites=true&w=majority
MONGODB_DB_NAME=kirana-napse

# JWT Authentication
JWT_SECRET=your-secret-key

Mobile App

Update firebase-credentials.json with your Firebase project credentials.

Deployment
Backend on Render

1. Create a new Web Service on Render
2. Select Python runtime
3. Link your GitHub repository
4. Configure build settings:
   - Build Command: pip install -r requirements.txt
   - Start Command: uvicorn main:app --host 0.0.0.0 --port $PORT
5. Add environment variables:
   - MONGODB_URL
   - MONGODB_DB_NAME
   - JWT_SECRET
   - KEEP_ALIVE_ENABLED: true
6. Enable auto-deploy on push

Mobile App on Firebase Hosting

1. Build for web:
   flutter build web --release

2. Deploy to Firebase Hosting:
   firebase deploy

Testing
Unit Tests

# Backend tests
python -m pytest tests/

# Frontend tests
flutter test

E2E Tests

# Run Flutter integration tests
flutter test integration_test/
