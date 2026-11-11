# ShopEase — Flutter + Node.js E-Commerce Mobile Application

> **Technical Interview Assignment** for **Axolotls Innovative Technologies**  
> **Role:** Full-Stack Mobile Developer (Flutter + Node.js)  
> **Submission Email:** `ajay.axolotls@gmail.com`  
> **Subject:** `Flutter + Node.js E-commerce Assignment — [Your Full Name]`

---

## 1. Project Overview & Architecture

**ShopEase** is a full-stack, beginner-friendly commercial mobile e-commerce application built with a modern **Flutter** frontend, an **Express.js / Node.js** REST API backend, and persistent data storage in **MongoDB**.

```
┌─────────────────────────────────┐
│     Flutter Mobile Client       │
│  - Material Design 3 UI         │
│  - Provider State Management    │
│  - http Client (10.0.2.2 / LAN) │
└───────────────▲─────────────────┘
                │ JSON / REST API + JWT Bearer
                ▼
┌─────────────────────────────────┐
│      Node.js & Express API      │
│  - Middleware: CORS, Auth (JWT) │
│  - Bcrypt Password Hashing      │
│  - Business Rules & Pricing     │
└───────────────▲─────────────────┘
                │ Mongoose ODM
                ▼
┌─────────────────────────────────┐
│       MongoDB Database          │
│  - Collections: User, Product,  │
│    Cart, Order                  │
└─────────────────────────────────┘
```

---

## 2. Technology Stack

- **Mobile Frontend**: Flutter 3.x, Dart 3.x
- **UI Design System**: Material Design 3, Responsive 2-column Grid, White Background, Royal Blue Palette (`#2563EB`)
- **State Management**: `provider` (Reactive Cart counter, Auth session, Product catalog, Order history)
- **Backend Framework**: Node.js & Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JSON Web Tokens (JWT) & `bcryptjs` password hashing (Salt rounds: 10)
- **Networking**: `http` package with dynamic Android emulator host detection (`10.0.2.2:5000`)

---

## 3. Project Directory Structure

```text
ShopEase/
│
├── backend_nodejs/                 # Complete Node.js / Express Backend
│   ├── config/
│   │   └── db.js                   # Mongoose MongoDB connection
│   ├── middleware/
│   │   └── auth.js                 # JWT Bearer token protection middleware
│   ├── models/
│   │   ├── User.js                 # User schema with bcrypt & JWT methods
│   │   ├── Product.js              # Product schema with stock & specifications
│   │   ├── Cart.js                 # Cart schema (userId + item subdocuments)
│   │   └── Order.js                # Order schema with immutable item snapshots
│   ├── routes/
│   │   ├── authRoutes.js           # Register, Login, Profile endpoints
│   │   ├── productRoutes.js        # Search, Category filter, Product details
│   │   ├── cartRoutes.js           # Add, update quantity, remove, server totals
│   │   └── orderRoutes.js          # Stock validation, place order, order history
│   ├── .env                        # Local environment variables
│   ├── .env.example                # Placeholder configuration template
│   ├── package.json                # Express & Mongoose dependencies
│   ├── seed.js                     # Realistic catalog database seeder
│   └── server.js                   # Express server entry point (Port 5000)
│
├── lib/                            # Flutter Mobile Application Source Code
│   ├── main.dart                   # MultiProvider root & AuthGate routing
│   ├── models/
│   │   ├── user.dart               # User entity
│   │   ├── product.dart            # Product entity with discount calculations
│   │   ├── cart_item.dart          # CartItem entity with line-item totals
│   │   └── order.dart              # OrderModel & OrderItemSnapshot
│   ├── providers/
│   │   ├── auth_provider.dart      # User session & token state
│   │   ├── product_provider.dart   # Catalog, search, and category filter
│   │   ├── cart_provider.dart      # Real-time cart calculations
│   │   └── order_provider.dart     # Order placement & history list
│   ├── services/
│   │   ├── api_config.dart         # Dynamic 10.0.2.2 Android loopback host
│   │   ├── auth_service.dart       # Auth HTTP client & JWT persistence
│   │   ├── product_service.dart    # Product fetch & fallback catalog
│   │   └── order_service.dart      # Order placement & history fetch
│   ├── screens/
│   │   ├── login_screen.dart       # Form validation & one-tap demo login
│   │   ├── register_screen.dart    # Registration with password match check
│   │   ├── main_navigation_screen.dart # 4-Tab Bottom navigation bar
│   │   ├── home_screen.dart        # Banner carousel, categories, 2-col grid
│   │   ├── categories_screen.dart  # Category browser & filtered grid
│   │   ├── product_details_screen.dart # Hero image, stock badge, quantity selector
│   │   ├── cart_screen.dart        # Empty state, item counters, price breakdown
│   │   ├── checkout_screen.dart    # Address form, payment selector, order sheet
│   │   ├── order_history_screen.dart # Color-coded status badges & receipts
│   │   └── profile_screen.dart     # User profile, live stats & safe logout
│   └── widgets/
│       ├── product_card.dart       # 2-column responsive product card
│       ├── custom_button.dart      # Primary / Outlined action buttons
│       └── custom_text_field.dart  # Form field with show/hide password toggle
│
├── test/
│   └── widget_test.dart            # 7 Unit & Widget tests (All passing)
├── postman_collection.json         # Postman API Collection with auto JWT capture
├── ShopEase_Ecommerce_Release.apk  # Ready-to-install Android Release APK
└── README.md                       # Complete Project Documentation
```

---

## 4. Prerequisites

Before running the project, ensure you have installed:
1. **Node.js** (v18.x or newer) and **npm**
2. **MongoDB Community Server** (v6.x or newer) running locally on port `27017`
3. **Flutter SDK** (v3.19 or newer) and **Dart SDK**
4. **Android Studio** with an active Android Emulator or physical Android device

---

## 5. Step-by-Step Setup & Run Instructions

### Step A: Setup & Run the Node.js / MongoDB Backend

1. Navigate to the backend directory:
   ```bash
   cd backend_nodejs
   ```
2. Install npm dependencies:
   ```bash
   npm install
   ```
3. Create your `.env` file from the example:
   ```bash
   cp .env.example .env
   ```
   *(Ensure `PORT=5000` and `MONGODB_URI=mongodb://127.0.0.1:27017/ecommerce_db`)*

4. Seed the database with sample products and a demo account:
   ```bash
   node seed.js
   ```
   *(Creates demo account: `demo@shop.com` / `password123` and 15+ sample products)*

5. Start the backend server:
   ```bash
   node server.js
   ```
   *The server starts on port `5000` and connects to `ecommerce_db`.*

6. Verify the server is running:
   ```bash
   curl http://localhost:5000/api/health
   ```

---

### Step B: Setup & Run the Flutter Mobile App

1. In a new terminal, navigate to the project root directory:
   ```bash
   cd ..
   ```
2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the complete unit and widget test suite:
   ```bash
   flutter test test/widget_test.dart
   ```
   *(All 7 tests will pass: models, calculations, auth form, empty cart, and product grid)*

4. Launch the application on your running Android emulator or device:
   ```bash
   flutter run
   ```

---

## 6. Pre-Configured Demo Credentials

For quick testing during interviews, you can either create a new user or use the pre-seeded account:
- **Email:** `demo@shop.com`
- **Password:** `password123`
*(The login screen also features a one-tap quick login for immediate review)*

---

## 7. REST API Endpoints Specification

All protected endpoints require the HTTP header:
`Authorization: Bearer <jwt_token>`

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/auth/register` | Public | Register new user with hashed password |
| `POST` | `/api/auth/login` | Public | Authenticate user & return signed JWT |
| `GET` | `/api/auth/me` | Protected | Get authenticated user profile |
| `PUT` | `/api/auth/me` | Protected | Update profile (name, phone, address) |
| `GET` | `/api/products` | Public | List products (`?search=...`, `?category=...`) |
| `GET` | `/api/products/categories` | Public | List all distinct categories |
| `GET` | `/api/products/:id` | Public | Get single product details |
| `GET` | `/api/cart` | Protected | Get current user's cart with server calculations |
| `POST` | `/api/cart/items` | Protected | Add product to cart with stock validation |
| `PATCH`| `/api/cart/items/:id` | Protected | Update item quantity |
| `DELETE`| `/api/cart/items/:id` | Protected | Remove item from cart |
| `DELETE`| `/api/cart` | Protected | Clear entire cart |
| `POST` | `/api/orders` | Protected | Validate stock, compute totals, place order |
| `GET` | `/api/orders` | Protected | List current user's order history |
| `GET` | `/api/orders/:id` | Protected | Get order receipt and delivery details |

---

## 8. Business Rules & Security Enforcements

1. **Passwords Are Never Stored in Plain Text**:
   - `bcryptjs` with 10 salt rounds hashes passwords before saving them to MongoDB.
2. **Untrusted Client Pricing**:
   - The frontend never dictates prices. Subtotal, taxes ($5\%$), and shipping fee (free for orders $\ge \$75$, else $\$9.99$) are computed authoritatively on the Express backend.
3. **Strict Stock Verification & Atomic Decrement**:
   - During checkout, every product's live stock is checked.
   - Stock is only decremented using `$inc: { stock: -quantity }` **after** the order document is successfully created.
4. **Data Isolation**:
   - Cart and Order queries are strictly scoped to `req.user._id` derived from verified JWT tokens. Users can never view or modify another customer's cart or orders.
5. **Immutable Receipts**:
   - Orders store snapshots of product details (`name`, `price`, `imageUrl`) so future catalogue price edits do not corrupt past order history.

---

## 9. Testing & Postman Collection

- **Postman**: Import [`postman_collection.json`](file:///c:/Users/Vishwajeet/FlutterProjects/test_app/postman_collection.json) into Postman. Running the "Login Customer" request automatically saves the JWT token into the `{{token}}` collection variable for all subsequent requests.
- **Flutter Tests**: Run `flutter test test/widget_test.dart` to execute unit tests for discount percentage, CartProvider business logic, OrderModel JSON mapping, and UI tests for Login, Cart, and Home screens.

---

## 10. Android Release APK

The standalone production APK is compiled and ready in the project root:
- **Location:** `ShopEase_Ecommerce_Release.apk`
- **Installation Command:**
  ```bash
  adb install -r ShopEase_Ecommerce_Release.apk
  ```
