# Sơn Xe Máy Cần Thơ - AI Agent Instructions

## Project Overview
Flutter mobile app for a motorcycle painting shop with 3 user roles: **Customer**, **Staff**, and **Manager**. Firebase backend (Auth, Firestore, Storage, Cloud Messaging). Node.js REST API exists but is **deprecated** - all new features use Firebase directly.

## Architecture & Data Flow

### Authentication Pattern
- **Customers**: Google Sign-In → stored in `users` collection
- **Staff/Manager**: Phone-based auth using email alias pattern (`84XXXXXXXXX@sonxemaycantho.employee.com`) → stored in `accounts` collection
- Role-based routing in [main.dart](lib/main.dart) `AuthWrapper` → determines home screen (CustomerHome, StaffHome, ManagerHome)
- **Critical**: Auth uses 15-second timeout to prevent hanging on slow connections

### Firestore Collections
```
users/           # Customer accounts (Google Sign-In)
accounts/        # Staff/Manager accounts (phone auth)
  ├─ phoneNumber, emailAlias, role, isActive, fullName
rooms/           # Chat rooms (participant pair sorted IDs as doc ID)
  └─ messages/   # Subcollection of messages
orders/          # Service orders with status tracking
serviceOrders/   # Batch orders from stores (legacy structure)
inventory/       # Stock management
```

### Screen Structure
- **Navigation**: Bottom navigation bar with badge notifications ([navigation_bar.dart](lib/widgets/navigation_bar.dart))
- **Routing**: Direct `Navigator.push` with MaterialPageRoute (no named routes)
- **State Management**: StreamBuilder for real-time Firestore data, FutureBuilder for async operations

## Key Patterns & Conventions

### Color & Styling
- **Always use**: [AppColors](lib/constants/app_colors.dart) constants (`AppColors.primary = #C1473B`)
- **Font**: `Itim` (Thai-style font) - set globally in theme
- **Gradients**: `AppColors.primaryGradient` for headers/cards
- Vietnamese UI text throughout

### Service Layer Structure
- [FirestoreService](lib/services/firestore.dart): Generic CRUD wrapper
- [ChatService](lib/services/chat_service.dart): Real-time messaging with typing indicators, unread counts
  - Room IDs: `{smallerUID}_{largerUID}` (sorted for consistency)
  - Batch operations for deleting rooms + messages
- [AuthService](lib/services/auth_service.dart): Dual auth system (Google + phone alias)
  - Phone normalization: `0xxx` → `84xxx` → email alias
  - Returns `Map<String, dynamic>` with user data on success

### Model Classes
- Use factory constructors: `fromFirestore(DocumentSnapshot)` and `fromMap(Map, String id)`
- Include `toMap()` for Firestore writes
- Timestamp handling: Convert `Timestamp` to `DateTime` in models
- Example: [ServiceOrder](lib/models/service_order.dart), [ChatRoom](lib/models/chat_room.dart)

### Error Handling & Debugging
- **Debug logging**: Use `if (kDebugMode) debugPrint()` extensively
- Firebase initialization check: `if (Firebase.apps.isEmpty)`
- Timeout pattern for Firestore queries (see [main.dart](lib/main.dart) `_fetchUserData`)
- Show user-friendly Vietnamese error messages in UI

## Developer Workflows

### Running the App
```bash
# Standard Flutter commands
flutter pub get
flutter run

# Generate splash screen/icons after changes
flutter pub run flutter_native_splash:create
flutter pub run flutter_launcher_icons:main
```

### Firebase Setup
- Config: [lib/widgets/firebase_options.dart](lib/widgets/firebase_options.dart) (auto-generated via FlutterFire CLI)
- Security rules: [firestore.rules](firestore.rules) - allows authenticated users, participant-based room access
- Composite indexes required for chat queries (see [firestore.indexes.json](firestore.indexes.json))

### Testing Firebase Locally
- Rules: Authenticated users can read their own `users/{uid}` or `accounts/{uid}`
- Chat: Users must be in `participants` array to read/write rooms

## Common Tasks

### Adding a New Screen
1. Create in appropriate role folder: `lib/screens/{customer,staff,manager}/`
2. Use `StatefulWidget` with AppBar containing `AppColors.primaryGradient`
3. Navigate with: `Navigator.push(context, MaterialPageRoute(builder: (context) => NewScreen()))`
4. Add to bottom nav if needed ([navigation_bar.dart](lib/widgets/navigation_bar.dart))

### Real-time Data Fetching
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('orders').snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    // Map to models using .fromFirestore()
  },
)
```

### Chat Feature Pattern
- Room creation: `ChatService().createOrGetRoom(otherUserId)` - auto-creates if not exists
- Messages: Query subcollection with `.orderBy('timestamp')` 
- Typing indicators: Update `typingUsers` map in room doc
- Unread badges: Increment `unreadCount[userId]` on send, reset on room open

### Role-Specific Features
- **Customer**: Order creation, chat with staff, view order status
- **Staff**: Accept orders, update status, manage inventory
- **Manager**: Staff account management (`isActive` toggle), view dashboard, export reports

## Critical Gotchas

1. **Phone Auth Email Suffix**: Must be unique (`@sonxemaycantho.employee.com`) - change if conflicts occur
2. **Room ID Sorting**: Always sort participant IDs before creating room ID to prevent duplicates
3. **Firestore Timestamps**: Use `FieldValue.serverTimestamp()` for creates, `Timestamp.fromDate()` for updates
4. **Inactive Accounts**: Check `isActive` field in `accounts` collection - must sign out inactive users
5. **Node.js API**: Legacy code in [server.js](server.js) - DO NOT use for new features (uses deprecated MongoDB)
6. **Build Variants**: Android has custom launcher icon/splash via gradle plugins

## Dependencies Notes
- `firebase_messaging` + `flutter_local_notifications`: Push notifications (configuration in platform-specific code)
- `image_picker`: Profile photos and order attachments → upload to Firebase Storage
- `bcrypt`: Used only in deprecated Node.js API
- `intl`: Date formatting for Vietnamese locale
