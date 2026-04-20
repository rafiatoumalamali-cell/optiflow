# OptiFlow - West African Logistics Optimization Platform

![OptiFlow Banner](assets/images/optiflow_logo.png)

A high-performance Flutter application designed to empower small and medium enterprises (SMEs) across West Africa with quantitative decision-making tools. OptiFlow integrates advanced optimization techniques—linear programming, network modeling, and route planning—to minimize costs and maximize operational throughput.

## 🚀 Overview

OptiFlow is an enterprise-grade logistics platform tailored for the unique challenges of the West African market. From navigating the busy hubs of Niamey and Lagos to managing cross-border corridors, OptiFlow provides real-time optimization with a robust offline-first architecture.

## ✨ Core Optimization Modules

### 🏢 **Product Mix Optimizer**
*   **LP-Powered Decisions**: Uses Linear Programming to determine the most profitable ratios of products based on resource constraints (labor, machines, materials).
*   **Strategy Dashboard**: Real-time visualization of projected profits and efficiency gains.
*   **Constraint Management**: Dynamic allocation of weekly resources with localized unit measurements.

### 🚚 **Transport & Logistics Hub**
*   **Network Modeling**: Optimizes supply and demand points to minimize transportation costs across regional corridors.
*   **Cross-Border Support**: Specialized logic for navigating arterial expressways through Zinder, Katsina, and other regional hubs.
*   **Vehicle Profiling**: Optimized for heavy-duty fleets common in the West African logistics sector.

### 📍 **Intelligent Route Planner**
*   **TSP Optimization**: Solves the Traveling Salesperson Problem to find the shortest delivery sequence.
*   **Proof of Delivery (POD)**: End-to-end delivery verification including **Digital Signatures** and **Photo Captures**.
*   **Assign to Driver**: Seamlessly push optimized routes from managers to driver mobile apps.
*   **Google Places Integration**: Real-time address search optimized for regional geography.

### 💰 **Dynamic Budget Allocation**
*   **Capital Optimization**: Intelligent split of capital across Production, Logistics, and Marketing.
*   **Regional Allocation**: Automated budgeting based on regional Hub performance (e.g., Niamey, Lagos, Accra).
*   **Savings Tracker**: Live MTD (Month-to-Date) savings metrics based on optimized decision outcomes.

## 🌍 West Africa Regional Adaptations

OptiFlow is built specifically for the regional context:

### **Supported Languages**
*   **English**: Primary business language.
*   **French**: Essential for Niger, Senegal, Côte d'Ivoire, and Burkina Faso.
*   **Hausa (Sannu!)**: Targeted support for Northern Nigeria and Niger regions.

### **Localized Currencies**
| Currency | Code | Countries |
|----------|------|-----------|
| West African CFA Franc | XOF (CFA) | Niger, Senegal, CI, Burkina Faso |
| Nigerian Naira | NGN (₦) | Nigeria |
| Ghanaian Cedi | GHS (₵) | Ghana |

## 🔒 Security & Role-Based Access (RBAC)

OptiFlow implements a strict security model to protect sensitive business data:
*   **Business Owners/Managers**: Full access to optimization engines, financial metrics, and driver management.
*   **Drivers**: Restricted access limited to assigned routes, navigation, and POD submission.
*   **Administrative Privacy**: Colleagues' data and administrative dashboards are programmatically blocked from unauthorized roles.

## 🛠️ Technical Infrastructure

For a deep dive into the algorithms and internal logic of OptiFlow, please refer to the [CORE_LOGIC.md](./CORE_LOGIC.md) file. This includes:
*   **Mathematical Models**: Detailed breakdown of the LP and TSP solvers.
*   **Sync Mechanisms**: How the offline-first SQLite/Firestore bridge operates.
*   **Security Protocol**: Specification of the Role-Based Access Control (RBAC) layers.

## 📱 Offline-First Architecture

Designed for challenging network environments:
*   **SQLite Local Cache**: All optimization results and locations are saved locally.
*   **Sync Queue Manager**: Background process that reconciles local changes with Firestore when connectivity returns.
*   **Connectivity Listener**: Real-time offline banners and status indicators.

## 🛠️ Technology Stack

*   **Frontend**: Flutter (3.x) with Provider State Management.
*   **Backend**: Python FastAPI with Google OR-Tools (Optimization Engine).
*   **Database**: Cloud Firestore (Real-time) + SQLite (Local).
*   **Maps**: Google Maps API (Directions, Distance Matrix, Places).
*   **Cloud Service**: Firebase (Auth, Analytics, Firestore, FCM).

## 📊 Project Structure

```text
lib/
├── screens/
│   ├── core/           # Dashboard, Results, Profile
│   ├── auth/           # Onboarding, Phone Auth, Role Setup
│   ├── product_mix/    # LP Optimization UI
│   ├── transport/      # Logistics Network UI
│   ├── route/          # TSP Route Planning & POD
│   ├── budget/         # Capital Allocation UI
│   └── driver/         # Driver-specific navigation
├── providers/          # State Management (ChangeNotifier)
├── services/           # API, Firebase, Maps, Database
├── models/             # Domain Models & Data Mapping
└── utils/              # Regional Localization & Theme
```

## 🚀 Getting Started

1.  **Clone the Repository**: `git clone https://github.com/optiflow/optiflow-mobile.git`
2.  **Install Dependencies**: `flutter pub get`
3.  **API Keys**: Add your Google Maps API Key to `local.properties` (Android) and `AppDelegate` (iOS).
4.  **Firebase**: Run `flutterfire configure` to connect your environment.
5.  **Run**: `flutter run`

---

**OptiFlow** - *Quantifying efficiency for West African Enterprise.*

*Built with ❤️ for the West African logistics community.*
