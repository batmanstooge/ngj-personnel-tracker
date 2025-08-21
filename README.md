Location Tracker App 

A comprehensive location tracking application with offline support, dark mode, and real-time GPS tracking across iOS, Android, and Web platforms. 
**Features** 
📍 Real-time Location Tracking 
    -Continuous GPS monitoring with visual markers on Google Maps
    -Distance-based location updates (10m minimum) for battery efficiency
    -Automatic location permission handling
     

📱 Offline Capabilities 
    -SQLite local database for offline location storage
   - Automatic sync when internet connection is restored
    -Visual indicators for online/offline status
    -Manual sync functionality
     

🌙 Dark Mode Support 
    -Toggle between light/dark themes
   - Respects system theme preferences
   - Smooth theme transitions with adaptive UI
    -Map style adaptation (normal/hybrid based on theme)
     

🔐 Secure Authentication 
    -Phone number-based login with OTP verification
    -JWT token authentication
    -Persistent login sessions
     

📅 Location History & Analytics 
    -Calendar-based location history browsing
   - Daily location summaries with first/last location tracking
    -Location data visualization on interactive maps
     

🌐 Cross-platform Support 
    -Native iOS and Android mobile apps
    -Web application support
    -Consistent user experience across platforms
     

**Tech Stack** 
Frontend (Flutter) 
    Framework: Flutter SDK
    Maps: Google Maps SDK for Flutter
    Location Services: Geolocator package
    Local Database: SQLite with SQFLite
    State Management: Provider package
    Networking: HTTP package
    Connectivity: Connectivity Plus
    UI Components: Material Design
     
Backend (Node.js) 
    Framework: Express.js
    Database: MongoDB with Mongoose
    Authentication: JWT (JSON Web Tokens)
    SMS Service: Twilio (for OTP)
    Environment Management: Dotenv


**Prerequisites** 
Development Tools 

    Flutter SDK (3.0+)
    Node.js (16+)
    MongoDB database
    Google Maps API key
    Twilio account (for SMS/OTP)
     

Platform-Specific Requirements 

    Android: Android Studio, Android SDK
    iOS: Xcode (macOS only)
    Web: Chrome browser for development
     

Setup Instructions 
1.**Backend Setup -- node**
Navigate to backend directory
cd backend

 Install dependencies
npm install

 Create environment file
cp .env.template .env

 Update .env with your configurations:
 - MongoDB connection string
 - JWT secret
 - Twilio credentials
- Google Maps API key

# Start backend server
npm run dev  # Development mode
 or
npm start    # Production mode


2.**Frontend Setup --flutter**
 Navigate to frontend directory
cd mobile_11

 Install Flutter dependencies
flutter pub get

 Configure Google Maps API keys:
 Android: android/app/src/main/AndroidManifest.xml
 iOS: ios/Runner/AppDelegate.swift
 Web: web/index.html

 Run the app
flutter run


3.**Platform-Specific Configuration** 
Android Configuration 
  Add to android/app/src/main/AndroidManifest.xml: 
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.INTERNET" />
  
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY"/>

iOS Configuration
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs access to location to track your movements.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs access to location to track your movements even when the app is in background.</string>

**Environment Variables** 
Backend (.env) 
  PORT=5000
  MONGODB_URI=mongodb://localhost:27017/locationtracker
  JWT_SECRET=your_jwt_secret_key
  TWILIO_ACCOUNT_SID=your_twilio_account_sid
  TWILIO_AUTH_TOKEN=your_twilio_auth_token
  TWILIO_PHONE_NUMBER=your_twilio_phone_number
  NODE_ENV=development
Backend (.env) 
