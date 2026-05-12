# GSTEase 🧾

**GSTEase** is a comprehensive Flutter-based mobile application designed to simplify GST (Goods and Services Tax) calculations, invoice generation, UPI payments, and financial management for businesses and individuals. The app integrates seamlessly with Firebase for authentication and data storage, making it a powerful tool for managing business finances.

---

## 📋 Table of Contents

- [Features](#-features)
- [Screenshots](#-screenshots)
- [Technology Stack](#-technology-stack)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Firebase Setup](#-firebase-setup)
- [UPI Setup](#-upi-setup)
- [Project Structure](#-project-structure)
- [Usage](#-usage)
- [Configuration](#-configuration)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)

---

## ✨ Features

### 🧮 GST Calculator
- **Inclusive & Exclusive GST Calculation**: Calculate GST with support for both inclusive and exclusive modes
- **Intra-State & Inter-State**: Automatic CGST/SGST or IGST calculation based on transaction type
- **Quick GST Rate Selection**: Pre-defined GST rates (0%, 5%, 18%, 40%) for quick calculations
- **Custom GST Rates**: Support for custom GST percentage input
- **Detailed Breakdown**: View complete breakdown of base price, GST components, and final price
- **Precision Calculations**: Accurate calculations rounded to 2 decimal places

### 📄 Invoice Generation
- **Professional PDF Invoices**: Generate professional-looking PDF invoices
- **Customizable Templates**: Add business details, customer information, and itemized lists
- **GST Compliance**: Automatically includes GST breakdowns (CGST/SGST/IGST)
- **Share & Print**: Direct sharing and printing capabilities
- **PDF Export**: Save invoices as PDF for record-keeping

### 💳 UPI Payment Integration
- **UPI Type Detection**: Real-time detection of bank vs. wallet UPI IDs
- **106 Bank UPI Handles**: Support for all major banks (ICICI, SBI, HDFC, Axis, etc.)
- **32 Wallet UPI Handles**: Support for popular wallets (PhonePe, Paytm, Google Pay, etc.)
- **Visual Indicators**: Shows bank/wallet icon before payment confirmation
- **Smart Caching**: UPI handles cached for 1 hour for improved performance
- **UPI Handle Helper**: Browse all available UPI handles
- **QR Code Generation**: Generate UPI QR codes for receiving payments
- **Payment History**: Track all UPI transactions
- **Fraud Reporting**: Report suspicious UPI transactions

### 💰 Financial Management
- **Investment Planning**: Salary-based investment recommendations
- **Tax Planning**: Investment suggestions for tax savings under Section 80C
- **SIP Calculator**: Calculate mutual fund SIP returns
- **Budget Recommendations**: Personalized budget allocation based on income
- **Retirement Planning**: Long-term financial planning tools

### 📊 Reports & Analytics
- **Transaction Reports**: Detailed reports of all transactions
- **GST Reports**: Summary of GST calculations and invoices
- **Payment Analytics**: Track payment patterns and history
- **Export Reports**: Export reports in PDF format

### 🔐 Authentication & Security
- **Firebase Authentication**: Secure user authentication
- **Email/Password Login**: Traditional authentication method
- **User Profile Management**: Manage user details and preferences
- **Secure Data Storage**: Cloud Firestore for secure data storage

### 📱 User Interface
- **Material Design 3**: Modern, clean UI with Material Design 3
- **Responsive Layout**: Optimized for various screen sizes
- **Dark/Light Theme**: Support for different viewing preferences
- **Intuitive Navigation**: Easy-to-use bottom navigation and drawer
- **Beautiful Animations**: Smooth transitions and animations

---

## 📱 Screenshots

<img width="336" height="748" alt="Screenshot_20260416_144426" src="https://github.com/user-attachments/assets/cacd0a67-36fb-41af-b499-7975c2586e70" />
<img width="336" height="748" alt="Screenshot_20260416_145230" src="https://github.com/user-attachments/assets/4a8a20ed-ddef-447e-a241-9c5f58f624aa" />


---

## 🛠 Technology Stack

### Frontend
- **Flutter** (SDK ^3.8.1): Cross-platform mobile development framework
- **Material Design 3**: Modern UI components and theming

### Backend & Services
- **Firebase Core** (^4.1.0): Firebase integration
- **Firebase Authentication** (^6.0.2): User authentication
- **Cloud Firestore** (^6.0.1): NoSQL cloud database

### Payment Integration
- **URL Launcher** (^6.2.2): Launch UPI payment apps
- **QR Flutter** (^4.1.0): Generate QR codes for UPI payments
- **HTTP** (^1.1.0): API calls for UPI handle validation

### Document Generation
- **PDF** (^3.10.7): PDF document creation
- **Printing** (^5.12.0): Print and share PDFs
- **Path Provider** (^2.1.2): Access file system paths
- **Permission Handler** (^11.3.0): Manage storage permissions

### Utilities
- **Shared Preferences** (^2.2.2): Local data persistence
- **Share Plus** (^7.2.2): Share files and content
- **Cupertino Icons** (^1.0.8): iOS-style icons

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.8.1 or higher)
  ```bash
  flutter --version
  ```
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control
- **Firebase Account** for backend services
- **Node.js** (for Firebase setup scripts)

---

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/gstease.git
cd gstease
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
Follow the [Firebase Setup](#-firebase-setup) section below.

### 4. Run the App
```bash
# For Android
flutter run

# For iOS (macOS only)
flutter run -d ios

# For Web
flutter run -d chrome
```

---

## 🔥 Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add Project"** and follow the wizard
3. Enable Google Analytics (optional)

### Step 2: Add Android App

1. In Firebase Console, click **"Add App"** → Select Android
2. **Package Name**: Enter your package name from `android/app/build.gradle.kts`
3. Download `google-services.json` and place it in `android/app/`

### Step 3: Add iOS App (Optional)

1. Click **"Add App"** → Select iOS
2. **Bundle ID**: Enter from `ios/Runner.xcodeproj`
3. Download `GoogleService-Info.plist` and add to `ios/Runner/`

### Step 4: Enable Firebase Services

#### Authentication
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password** authentication

#### Cloud Firestore
1. Go to **Firestore Database** → **Create Database**
2. Start in **test mode** (or production mode with custom rules)
3. Choose your region
4. Deploy security rules from `firestore.rules`

#### Firestore Security Rules
Deploy the security rules:
```bash
firebase deploy --only firestore:rules
```

### Step 5: Generate Firebase Options

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will generate `lib/firebase_options.dart` automatically.

### Step 6: Service Account Key (for UPI Handles)

1. Go to **Project Settings** → **Service Accounts**
2. Click **"Generate New Private Key"**
3. Save as `serviceAccountKey.json` in project root
4. **IMPORTANT**: Add to `.gitignore` to keep it secure

---

## 💳 UPI Setup

The app includes sophisticated UPI type detection that identifies bank vs. wallet UPI IDs. See [UPI_SETUP_README.md](UPI_SETUP_README.md) for detailed setup instructions.

### Quick Setup

1. **Create Firebase Collection**:
   ```bash
   node create_handles_collection.js
   ```

2. **Features**:
   - 106 bank UPI handles supported
   - 32 wallet UPI handles supported
   - Real-time UPI type detection
   - Visual indicators for payment confirmation
   - Cached handles for performance

### UPI Handles Supported

**Banks**: `@icici`, `@sbi`, `@hdfc`, `@axis`, `@ybl` (Yes Bank), `@oksbi`, `@okaxis`, and 99 more

**Wallets**: `@paytm`, `@phonepe`, `@gpay`, `@amazonpay`, `@mobikwik`, and 27 more

---

## 📁 Project Structure

```
gstease/
├── android/                  # Android-specific files
├── ios/                      # iOS-specific files
├── lib/
│   ├── main.dart            # App entry point
│   ├── auth_wrapper.dart    # Authentication wrapper
│   ├── login_screen.dart    # Login page
│   ├── registration_screen.dart  # Registration page
│   ├── gst_calculator_screen.dart  # GST calculator
│   ├── invoice_screen.dart  # Invoice generation
│   ├── upi_payment_screen.dart  # UPI payment
│   ├── upi_receive_screen.dart  # UPI QR code generation
│   ├── rate_tracker_screen.dart  # Rate tracking
│   ├── manager_screen.dart  # Financial planning
│   ├── reports_screen.dart  # Reports & analytics
│   ├── profile_screen.dart  # User profile
│   ├── payment_history_screen.dart  # Payment history
│   ├── upi_fraud_report_screen.dart  # Fraud reporting
│   ├── firebase_options.dart  # Firebase configuration
│   ├── services/
│   │   ├── upi_handle_service.dart  # UPI handle detection
│   │   └── fraud_report_service.dart  # Fraud reporting service
│   └── config/              # Configuration files
├── assests/
│   └── icon/                # App icons and images
├── firestore.rules          # Firestore security rules
├── firestore.indexes.json   # Firestore indexes
├── firebase.json            # Firebase configuration
├── pubspec.yaml             # Dependencies
└── README.md                # This file
```

---

## 💡 Usage

### First Time Setup

1. **Launch the App**
2. **Register**: Create a new account with email and password
3. **Login**: Access your dashboard

### GST Calculator

1. Navigate to **GST Calculator** from the home screen
2. Select calculation mode (Inclusive/Exclusive)
3. Choose transaction type (Intra-State/Inter-State)
4. Enter amount and GST rate (or use quick select)
5. View detailed breakdown

### Generate Invoice

1. Go to **Invoice** screen
2. Fill in business and customer details
3. Add items with quantities and prices
4. Select GST rate and transaction type
5. Preview and generate PDF
6. Share or save the invoice

### UPI Payment

1. Navigate to **UPI Payment** screen
2. Enter recipient UPI ID (auto-detects bank/wallet)
3. Enter amount and description
4. Review payment details in popup
5. Confirm and launch UPI app
6. Complete payment in your UPI app

### Receive UPI Payment

1. Go to **Receive Payment** screen
2. Enter your UPI ID and amount
3. Generate QR code
4. Customer scans QR code to pay

### Financial Planning

1. Open **Manager** screen
2. Enter your monthly/yearly salary
3. View personalized investment recommendations
4. Explore tax-saving options
5. Use SIP calculator for mutual fund planning

---

## ⚙️ Configuration

### App Icon

The app uses a custom launcher icon located at `assests/icon/GSTEase Logo.PNG`.

To update the icon:
```bash
flutter pub run flutter_launcher_icons
```

### Firebase Configuration

Configuration files:
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Flutter**: `lib/firebase_options.dart`

### Firestore Indexes

Required indexes are defined in `firestore.indexes.json`. Deploy them:
```bash
firebase deploy --only firestore:indexes
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Open a Pull Request**

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Run `flutter analyze` before committing
- Format code with `dart format .`

---

## 📄 License

This project is private and not licensed for public distribution. All rights reserved.

---

## 📞 Support

For support, questions, or feedback:

- **Email**: support@gstease.com (if applicable)
- **Issues**: Open an issue on GitHub
- **Documentation**: Check [UPI_SETUP_README.md](UPI_SETUP_README.md) for UPI-specific help

---

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Firebase** for backend services
- **Material Design** for UI guidelines
- **UPI** ecosystem for payment integration
- All open-source contributors whose packages made this possible

---

## 🔮 Future Roadmap

- [ ] Multi-language support
- [ ] Offline mode with local database
- [ ] Advanced analytics dashboard
- [ ] WhatsApp integration for invoice sharing
- [ ] Recurring invoice templates
- [ ] Expense tracking
- [ ] OCR for bill scanning
- [ ] Cloud backup and sync
- [ ] Multi-user business accounts
- [ ] API for third-party integrations

---

**Made with ❤️ using Flutter**
