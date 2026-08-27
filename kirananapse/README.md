# Kirana-Napse Mobile App (Flutter)

AI-Powered Demand Forecasting & Reorder Assistant for Kirana Stores.

## Screens & User Journeys (AppFlow v2.0)
1. **Authentication** (`LoginScreen`, `RegisterScreen`)
2. **Onboarding Flow (5 Screens)**:
   - Step 1: Language Picker (Hindi, English, Marathi, Tamil, Telugu)
   - Step 2: Push Notification Permission Walkthrough
   - Step 3: Store Basics (Category chips, SKU count slider, Area)
   - Step 4: Current Tracking Method (Memory / Register / Billing App)
   - Step 5: Confirmation & What to Expect
3. **Main Dashboard (`HomeScreen`)**:
   - Summary Stat Cards: Items to Reorder, Low Stock, Overstocked, Expiry Risk
   - Quick Action Tiles: Export Order List, Add Sales
   - Top Reorder Items Preview with pull-to-refresh
4. **Reorder List (`ReorderListScreen`)**:
   - Editable quantity, cold-start indicators, Order / Skip action buttons
5. **Overstock & Expiry (`OverstockScreen`)**:
   - Color-coded alerts (orange for slow-movers, red for perishable expiry risk)
6. **Item Detail (`ItemDetailScreen`)**:
   - Sales history sparkline placeholder, plain-language forecast reasoning, quantity editor
7. **Distributor Export (`DistributorExportScreen`)**:
   - Formatted forwardable order summary with one-tap Android Share-Sheet to WhatsApp
8. **Feedback Prompt (`FeedbackPromptScreen`)**:
   - Reason codes (Festival, Bulk Buyer, Weather, Competitor, Other) + free text
9. **Settings (`SettingsScreen`)**:
   - Profile, language preference, push notification toggle, privacy info, logout
10. **Sales Data Entry (`ManualEntryScreen`)**:
    - Item name, quantity, unit dropdown, revenue, and photo/OCR bill entry point

## How to Run Locally
```bash
# In kirananapse/ directory:
flutter pub get
flutter run
```
