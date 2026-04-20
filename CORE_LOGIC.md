# OptiFlow Technical Architecture & Core Logic

This document provides a deep dive into the engineering principles, algorithms, and logical workflows that power the OptiFlow logistics application.

## 1. Optimization Methodology

OptiFlow offloads computationally intensive tasks to a Python FastAPI backend utilizing **Google OR-Tools**.

### **A. Product Mix Optimization (Linear Programming)**
*   **Logic**: Solves for $X_1, X_2...X_n$ (quantity produced) to maximize $\sum (Profit_i \times X_i)$.
*   **Constraints**: Subject to $\sum (Usage_{ij} \times X_i) \leq Capacity_j$.
*   **Implementation**: The mobile app sends a JSON matrix of products and resource requirements. The backend uses the `GLOP` (Google Linear Optimization Package) solver to return the optimal production quantities and the shadow price (efficiency) of each resource.

### **B. Transportation Optimization (Network Flows)**
*   **Logic**: Minimizes total transportation cost $\sum (Cost_{ij} \times Flow_{ij})$.
*   **Constraints**: 
    *   $\sum Flow_{ij} \leq Supply_i$
    *   $\sum Flow_{ij} \geq Demand_j$
*   **Implementation**: Uses the `Transportation Simplex` method. The app calculates distance matrices via the Google Maps API, which are then passed to the backend to find the least expensive supply-to-demand mapping.

### **C. Route Optimization (TSP/VRP)**
*   **Logic**: Solves the Traveling Salesperson Problem (TSP) to minimize $Distance_{total}$.
*   **Implementation**: 
    1.  The manager selects $N$ locations.
    2.  The app fetches a $N \times N$ Distance/Time matrix.
    3.  The backend uses the `RoutingModel` from OR-Tools to find the sequence that minimizes travel time while respecting "Start" and "End" location roles.
    4.  The optimized sequence is pushed to the Driver via **Firebase Cloud Messaging**.

---

## 2. Data Synchronization (Offline-First)

OptiFlow is designed for high-latency or zero-connectivity environments common in regional West African corridors.

### **The Sync Queue Logic**
1.  **Local Write**: When a user adds a product or location, it is immediately written to a local **SQLite** database.
2.  **Operation Queueing**: A JSON object representing the change (INSERT/UPDATE/DELETE) is added to the `sync_queue` table with a `pending` status.
3.  **Connectivity Listener**: Using the `connectivity_plus` package, the app monitors network state.
4.  **Sync Execution**:
    *   Once online signal is detected, the `SyncManager` processes the queue sequentially.
    *   Records are pushed to **Firestore**.
    *   On success, the local queue item is cleared.
5.  **Conflict Resolution**: OptiFlow uses a "Last Write Wins" strategy supported by Firestore's `serverTimestamp()`.

---

## 3. Role-Based Access Control (RBAC) Architecture

Security is enforced at multiple layers to protect sensitive business intelligence from the driver role.

### **A. UI-Layer Security**
*   The `AppDrawer` uses a `Consumer<AuthProvider>` to conditionally build menu items.
*   Administrative modules (Optimization, Budget) are completely omitted from the widget tree if `user.role != 'manager'`.

### **B. Navigation-Layer Security**
*   The `NavigationService` includes a `RouteGuard`. Any attempt to access an administrative route via deep link or manual navigation triggers a role check.
*   Unauthorized attempts redirect the user back to the `DriverHomeScreen`.

### **C. Data-Layer Security (Firestore Rules)**
```text
match /businesses/{businessId} {
  allow read: if request.auth.uid != null;
  allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['owner', 'manager'];
}
```

---

## 4. Proof of Delivery (POD) Workflow

The POD system ensures accountability and data integrity for every delivery stop.

### **Logic Flow**:
1.  **Arrive**: Driver marks a stop as "Arrived" (GPS coordinates are validated against the target location within a 50m geofence).
2.  **Capture**: Driver takes a photo of the goods/invoice.
3.  **Sign**: User provides a signature on the digital canvas.
4.  **Persistence**:
    *   The signature (Base64) and Photo are uploaded to **Firebase Storage**.
    *   The download URLs are attached to the `OptimizationResultModel` or `RouteModel`.
    *   The status of the stop is updated to `completed` in Firestore.
5.  **Confirmation**: The manager receives a push notification and can view the POD in the "Saved Results" screen.

---

## 5. Regional Financial Calculation Logic

OptiFlow dynamic metrics (Savings MTD) are calculated by comparing optimized outcomes vs. flat benchmarks.

*   **Product Mix Savings**: (Optimized Profit - Estimated Baseline Profit).
*   **Logistics Savings**: (Standard Routing Cost - Optimized Routing Cost).
*   **Currency Handling**: A centralized `CurrencyProvider` monitors the `BusinessSettings`. All financial values are passed through a `CurrencyFormatter` extension that applies the correct symbol (CFA, ₦, ₵) and decimal formatting based on regional standards.
