# 🗨️ Chatter — iOS App Project Overview

> **Platform:** iOS (SwiftUI)  
> **Architecture:** MVVM (Model–View–ViewModel)  
> **Backend:** Node.js / Express REST API  
> **Language:** Swift  
> **Min Deployment:** iOS 16+ (uses `NavigationStack`, `PhotosPicker`, modern concurrency)

---

## 📁 Project Structure

```
chatter/
├── App/                        # App entry point & global state
│   ├── chatterApp.swift         # @main SwiftUI app entry
│   ├── AppState.swift           # Global auth state, banner system, appearance, socket lifecycle
│   └── KeychainManager.swift    # Secure token storage via iOS Keychain
│
├── Features/                   # Feature modules (MVVM per feature)
│   ├── Auth/                    # Login, Register, Forgot Password
│   ├── Feed/                    # Social media feed with pagination
│   ├── People/                  # User discovery, friends, requests
│   ├── Chat/                    # Conversations & messaging
│   ├── Post/                    # Create posts, comments, likes
│   ├── Profile/                 # User profiles, edit profile, avatar
│   ├── Notifications/           # Activity feed with real-time updates
│   └── Settings/                # Password change, delete account, appearance
│
├── Models/                     # Data models (Codable)
│   ├── User.swift               # User model + paginated responses
│   ├── Post.swift               # Post model with media types
│   ├── Comment.swift            # Comment model
│   ├── Conversation.swift       # Conversation model (DM + Group)
│   ├── Message.swift            # Message model with read receipts
│   ├── FriendRequest.swift      # Friend request model with status
│   └── AppNotification.swift    # Notification model with types & metadata
│
├── CoreData/                   # Offline Persistence Engine
│   ├── PersistenceController.swift # NSPersistentContainer & programmatic schema
│   ├── CoreDataManager.swift   # High-level thread-safe caching & CRUD operations
│   └── CoreDataEntities.swift   # CDUser, CDPost, CDComment, CDConversation, CDMessage, CDNotification
│
├── Networking/                 # API layer
│   ├── APIClient.swift          # Singleton HTTP client (JSON + multipart)
│   ├── APIEndpoint.swift        # All API endpoint definitions
│   ├── APIError.swift           # Typed error handling
│   ├── AuthInterceptor.swift    # Bearer token injection & 401 handling
│   └── SocketService.swift      # Socket.IO v4 client (native URLSessionWebSocketTask)
│
├── Components/                 # Reusable UI components
│   ├── AvatarView.swift         # User avatar with initials fallback
│   ├── MediaPlayerView.swift    # Image + video player with download
│   ├── DownloadToastView.swift  # Download progress toast overlay
│   ├── EmptyStateView.swift     # Empty state placeholder
│   ├── ErrorBanner.swift        # Global error/success/info banners
│   ├── OfflineBannerView.swift  # Dynamic animated banner for offline mode
│   ├── LoadingView.swift        # Loading state animations
│   └── PrimaryButton.swift      # Branded button component
│
├── Navigation/                 # App navigation
│   ├── RootView.swift           # Auth/Main router with banner overlay
│   ├── MainTabView.swift        # 5-tab navigation (Feed, People, Chat, Activity, Profile)
│   └── AuthCoordinator.swift    # Auth flow coordinator
│
├── Extensions/                 # Swift extensions
│   ├── Color+Theme.swift        # Brand color system (dark/light mode)
│   ├── Font+Custom.swift        # Custom typography
│   └── View+Extensions.swift    # Card modifier, shimmer effect, date helpers
│
├── Utilities/                  # Shared services & helpers
│   ├── AppConfig.swift          # Base URL configuration
│   ├── DownloadManager.swift    # Media download to Files app
│   ├── NetworkMonitor.swift     # NWPathMonitor network connectivity watcher
│   ├── PostActionService.swift  # Shared like/unlike logic (optimistic UI)
│   └── URLResolver.swift        # Relative → absolute URL resolution
│
└── Info.plist                  # File sharing enabled for downloads
```

---

## ✅ Features Implemented

### 1. 🔐 Authentication
| Feature | Description |
|---------|-------------|
| **Login** | Email/username + password authentication |
| **Registration** | Full name, username, email, password with validation |
| **Forgot Password** | Email-based password reset flow |
| **Secure Token Storage** | JWT stored in iOS Keychain (`kSecAttrAccessibleAfterFirstUnlock`) |
| **Auto Session Restore** | Token checked on app launch, user profile auto-fetched |
| **Session Expiry Handling** | 401 responses auto-logout via `NotificationCenter` |

### 2. 📰 Social Feed
| Feature | Description |
|---------|-------------|
| **Paginated Feed** | Infinite scroll with automatic page loading (20 posts/page) |
| **Pull to Refresh** | Swipe-down refresh resets pagination |
| **Post Cards** | Rich post cards with author info, text, media, likes, comments |
| **Like/Unlike** | Optimistic UI toggle with haptic feedback |
| **Post Deletion** | Owner can delete posts with animated removal |
| **Media Display** | Inline image/video rendering in feed cards |

### 3. 📝 Post Creation
| Feature | Description |
|---------|-------------|
| **Text Posts** | Create text-only posts |
| **Image Posts** | Upload images via PhotosPicker |
| **Video Posts** | Upload videos via PhotosPicker |
| **Media Preview** | Preview selected image/video before posting |
| **Multipart Upload** | Media uploaded as `multipart/form-data` |

### 4. 💬 Comments & Interactions
| Feature | Description |
|---------|-------------|
| **View Comments** | Full comment thread on post detail |
| **Add Comments** | Submit comments with optimistic UI insertion |
| **Delete Comments** | Remove own comments |
| **Like/Unlike Posts** | Separate like and unlike API endpoints |

### 5. 👥 People & Social Graph
| Feature | Description |
|---------|-------------|
| **All Users** | Browse all registered users with pagination |
| **Search People** | Search users by name/username |
| **Friends List** | View and search accepted friends |
| **Friend Requests** | View received & sent requests with search |
| **Send Request** | Send friend request with haptic feedback |
| **Accept/Decline/Cancel** | Full friend request lifecycle management |
| **Remove Friend** | Unfriend with animated list removal |
| **Tabs** | 3-tab segmented UI: All People, Friends, Requests |

### 6. 💬 Chat & Messaging
| Feature | Description |
|---------|-------------|
| **Conversations List** | Paginated list of all conversations |
| **Direct Messages (DM)** | 1-on-1 chat creation and messaging |
| **Group Chats** | Create group conversations with custom names |
| **Send Messages** | Text messaging with conversation context |
| **Message History** | Paginated message loading per conversation |
| **Read Receipts** | Mark messages as read |
| **Delete Messages** | Remove individual messages |
| **Leave Conversation** | Exit group conversations |
| **New Chat Sheet** | Start new DM from friends list or search |
| **Participant Enrichment** | Auto-populate participant details post-creation |

### 7. 👤 User Profile
| Feature | Description |
|---------|-------------|
| **Own Profile** | View personal profile with stats (posts, friends) |
| **Other User Profiles** | View any user's profile by username |
| **Edit Profile** | Update full name, username, bio |
| **Avatar Upload** | Profile picture upload via PhotosPicker (multipart) |
| **Posts Grid** | User's posts displayed in grid layout |
| **Friend Actions** | Context-aware button: Add Friend / Cancel / Accept / Message / Edit |
| **Relationship Detection** | Auto-evaluates friendship status on profile load |
| **Start Conversation** | Direct message button on friend profiles |

### 8. 🔔 Notifications & Real-Time
| Feature | Description |
|---------|-------------|
| **Activity Feed** | Paginated notification list with pull-to-refresh |
| **Notification Types** | `message`, `friend_request`, `friend_request_accepted`, `like`, `comment` |
| **Type Badges** | Color-coded icon badge overlay on actor avatar (❤️ like, 💬 comment, 👤 friend) |
| **Read / Unread** | Blue dot indicator + tinted background for unread items |
| **Mark as Read** | Tap to mark individual notification as read (optimistic UI) |
| **Mark All Read** | Toolbar button to mark all notifications read at once |
| **Tab Badge** | Live unread count badge on the Activity tab |
| **Socket.IO Real-Time** | New notifications arrive instantly via WebSocket |
| **Auto-Reconnect** | Exponential backoff reconnection (2s → 30s, max 10 attempts) |
| **Foreground Resume** | Socket reconnects and badge refreshes on app foreground |
| **Haptic Feedback** | Light impact on new real-time notification |

### 9. ⚙️ Settings
| Feature | Description |
|---------|-------------|
| **Appearance Toggle** | System / Light / Dark mode selector (persisted via `@AppStorage`) |
| **Change Password** | Old + new password with validation |
| **Delete Account** | Permanent account deletion with confirmation |
| **Logout** | Secure logout with Keychain token cleanup + socket disconnect |
| **App Info** | Version display (1.0.0) and backend info |

### 9. 📥 Media Download
| Feature | Description |
|---------|-------------|
| **Download to Files** | Save images/videos to `Documents/Chatter/Photos` or `Videos` |
| **File Sharing** | `UIFileSharingEnabled` — files visible in iOS Files app |
| **Toast Notifications** | Download progress and success/failure toasts |
| **Smart Extensions** | Auto-detect file extensions from URL or fallback defaults |

---

## 🌐 API Endpoints Integrated

### Authentication (`/api/auth/`)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/auth/register` | Register new user |
| `POST` | `/auth/login` | Login with identifier + password |
| `POST` | `/auth/forgot-password` | Send password reset email |

### Users (`/api/user/`)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/user/profile` | Get current user's profile |
| `GET` | `/user/:username` | Get another user's profile |
| `PUT` | `/user/updateProfile` | Update profile fields |
| `PATCH` | `/user/profilePicture` | Upload avatar (multipart) |
| `PUT` | `/user/updatePassword` | Change password |
| `DELETE` | `/user/delete` | Delete account |

### Friends (`/api/friend/`)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/friend/allUsers` | Browse all users (paginated) |
| `GET` | `/friend/searchPeople` | Search users by query |
| `GET` | `/friend/friendsList` | List accepted friends |
| `GET` | `/friend/searchFriends` | Search within friends |
| `GET` | `/friend/friendRequests` | Received friend requests |
| `GET` | `/friend/sentRequests` | Sent friend requests |
| `GET` | `/friend/searchFriendRequests` | Search friend requests |
| `POST` | `/friend/sendRequest/:userId` | Send friend request |
| `POST` | `/friend/acceptRequest/:requestId` | Accept friend request |
| `POST` | `/friend/declineRequest/:requestId` | Decline friend request |
| `POST` | `/friend/cancelRequest/:requestId` | Cancel sent request |
| `DELETE` | `/friend/deleteFriend/:friendId` | Remove friend |

### Posts (`/api/post/`)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/post/feed` | Get feed posts (paginated) |
| `POST` | `/post/createPost` | Create post (multipart) |
| `DELETE` | `/post/deletePost/:postId` | Delete a post |
| `GET` | `/post/userPosts/:userId` | Get user's posts |
| `GET` | `/post/myPosts` | Get current user's posts |

### Comments & Likes (`/api/comment/`)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/comment/getComments/:postId` | Get post comments |
| `POST` | `/comment/createComment/:postId` | Add comment |
| `DELETE` | `/comment/deleteComment/:commentId` | Delete comment |
| `POST` | `/comment/likePost/:postId` | Like a post |
| `POST` | `/comment/unlikePost/:postId` | Unlike a post |

### Conversations (`/api/conversation/`)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/conversation` | List conversations (paginated) |
| `POST` | `/conversation/create` | Create conversation (DM or group) |
| `DELETE` | `/conversation/:id/leave` | Leave conversation |
| `DELETE` | `/conversation/:id/participants/:userId` | Remove participant |

### Messages (`/api/message/`)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/message/conversation/:conversationId` | Send message |
| `GET` | `/message/conversation/:conversationId` | Get messages (paginated) |
| `PATCH` | `/message/:messageId/read` | Mark as read |
| `DELETE` | `/message/:messageId` | Delete message |

### Notifications (`/api/notification/`)
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/notification` | List notifications (paginated, newest first) |
| `GET` | `/notification/unread-count` | Get unread badge count |
| `PATCH` | `/notification/:id/read` | Mark one notification as read |
| `PATCH` | `/notification/read-all` | Mark all notifications as read |

### Socket.IO (Real-Time)
| Event | Direction | Payload | Use |
|-------|-----------|---------|-----|
| `notification:new` | Server → Client | `AppNotification` object | Insert at top, increment badge |
| `notification:read` | Server → Client | `{ notificationId, readAt }` | Update item, decrement badge |
| `notification:read_all` | Server → Client | *(none)* | Clear all unread, reset badge |

**Total: 34+ REST API endpoints + 3 Socket.IO events integrated**

---

## 🧱 Data Models

| Model | Key Fields | Notes |
|-------|------------|-------|
| **User** | `id`, `fullName`, `username`, `email`, `bio`, `avatarURL`, `postsCount`, `friendsCount` | Handles both `id` and `_id` (MongoDB) |
| **Post** | `id`, `author`, `text`, `mediaURL`, `mediaType`, `likesCount`, `commentsCount`, `isLikedByMe` | Supports `none`, `image`, `video` media types |
| **Comment** | `id`, `post`, `author`, `text`, `createdAt` | Backend sends `content`, app maps to `text` |
| **Conversation** | `id`, `participants`, `isGroup`, `groupName`, `groupAdmin`, `lastMessage` | Supports both DM and group chat |
| **Message** | `id`, `conversation`, `sender`, `text`, `mediaUrl`, `readBy` | Sender can be populated object or string ID |
| **FriendRequest** | `id`, `sender`, `receiver`, `status` | Status: `pending`, `accepted`, `declined`, `cancelled` |
| **AppNotification** | `id`, `recipient`, `actor`, `type`, `entityType`, `entityId`, `message`, `metadata`, `readAt` | Types: `message`, `friend_request`, `friend_request_accepted`, `like`, `comment` |

All models implement custom `Codable` with robust decoding to handle server response variations (e.g., `_id` vs `id`, `avatar` vs `avatarURL`, `content` vs `text`).

---

## 🎨 Design System

### Color Palette
| Token | Purpose |
|-------|---------|
| `chatterPrimary` | Brand purple (#7268FA dark / #5952EB light) |
| `chatterSecondary` | Accent pink (#F25A8D dark / #E6407A light) |
| `chatterGradient` | Primary → Secondary gradient |
| `chatterBackground` | Page background |
| `chatterCardBackground` | Card surfaces |
| `chatterText` / `chatterSubtext` | Typography hierarchy |
| `chatterSuccess` / `chatterWarning` / `chatterDestructive` | Semantic colors |

### UI Components
- **ChatterCardModifier** — Rounded card with shadow and border
- **ShimmerModifier** — Loading skeleton animation
- **AvatarView** — Avatar with URL image or initials fallback
- **MediaPlayerView** — Image/video player with full-screen & download
- **ErrorBanner** — Animated global notification banners (success/error/info)
- **PrimaryButton** — Branded gradient button
- **LoadingView** — Full-screen loading indicator
- **EmptyStateView** — Placeholder for empty lists

### Dark/Light Mode
- Full dark mode support via `preferredColorScheme`
- Colors adapt using `UIColor { traitCollection }` closures
- User preference persisted via `@AppStorage("appAppearanceSelection")`

---

## 🏗️ Architecture & Patterns

### MVVM Architecture
Every feature follows a clean **View → ViewModel → APIClient** pattern:

```
View (SwiftUI)
  ↕ @StateObject / @ObservedObject
ViewModel (ObservableObject, @MainActor)
  ↕ async/await (REST)  +  Combine (Socket.IO events)
APIClient (Singleton) → Backend REST API
SocketService (Singleton) → Backend Socket.IO (WebSocket)
```

### Key Design Patterns
| Pattern | Implementation |
|---------|---------------|
| **Singleton** | `APIClient.shared`, `KeychainManager.shared`, `AuthInterceptor.shared`, `SocketService.shared` |
| **Environment Object** | `AppState` injected globally for auth state & notification badge |
| **Optimistic UI** | Likes toggle instantly, API fires in background |
| **Interceptor** | `AuthInterceptor` injects Bearer token & handles 401 expiry |
| **Observer** | `NotificationCenter` for session expiry & foreground resume |
| **Pub/Sub** | Combine `PassthroughSubject` for Socket.IO event distribution |
| **Offline Persistence** | Core Data SQLite cache with automated schema migration & conflict trump |
| **Cache-First Hydration** | ViewModels load local Core Data cache first (0ms load), then fetch fresh server data |
| **Connectivity Monitoring** | `NetworkMonitor` (`NWPathMonitor`) detects online/offline status with live UI indicators |
| **Multipart Upload** | Custom `Data` boundary builder for file uploads |
| **URL Resolution** | Centralized relative-to-absolute URL mapping |
| **Haptic Feedback** | `UIImpactFeedbackGenerator` on social actions |
| **Pagination** | Cursor-based infinite scroll with dedup on append |

### Offline & Core Data Layer
- **Zero-Config Programmatic Model** — Pure Swift `NSManagedObjectModel` with no Xcode model compilation quirks
- **Entity Architecture** — `CDUser`, `CDPost`, `CDComment`, `CDConversation`, `CDMessage`, `CDNotification`
- **Thread Safety** — Background context saves merge automatically into `viewContext` with `NSMergeByPropertyObjectTrumpMergePolicy`
- **Two-Way Bridge** — Effortless conversion between Swift struct domain models (`Post`, `User`, `Message`, etc.) and Core Data managed objects
- **Offline Banner** — Non-intrusive animated pill banner (`OfflineBannerView`) informs users when displaying cached content

### Networking Layer
- **Generic APIClient** — `request<T: Decodable>()` with typed decoding
- **Envelope Pattern** — Unwraps `{ success, message, data }` wrapper
- **Multipart Support** — `uploadMultipart<T>()` for image/video uploads
- **Custom Date Decoding** — Handles 5 ISO8601 format variations
- **Timeout Config** — 2 min request / 10 min resource (for large video uploads)

### Security
- JWT tokens stored in **iOS Keychain** (not UserDefaults)
- Token auto-deleted on 401 response
- `kSecAttrAccessibleAfterFirstUnlock` — available after first device unlock
- Bearer token injected via interceptor pattern
- Local Core Data store automatically wiped upon user logout

---

## 📊 Project Statistics

| Metric | Count |
|--------|-------|
| **Swift Source Files** | ~55 |
| **Feature Modules** | 8 (Auth, Feed, People, Chat, Post, Profile, Notifications, Settings) |
| **Data Models** | 7 core models + 11 response/pagination types |
| **Core Data Entities** | 6 managed entities with full relational serialization |
| **API Endpoints** | 34+ |
| **Socket.IO Events** | 3 |
| **Reusable Components** | 8 |
| **ViewModels** | 9 |
| **Views** | 25 |
| **Extensions** | 3 files |
| **Utilities** | 5 services |

---

## 🔧 Technical Highlights

1. **100% async/await** — No completion handlers, all networking uses Swift concurrency
2. **Offline-First Persistence** — Complete Core Data stack powers instant app loading, feed browsing, message reading, and activity feed access without internet
3. **Robust Codable** — Every model handles server inconsistencies gracefully (dual field keys, optional objects vs strings)
4. **File Downloads** — Media saved to app's Documents directory, visible in iOS Files app
5. **Optimistic Updates** — Likes, comments, notifications, and friend actions update UI and local cache instantly
6. **Live Connectivity Awareness** — `NetworkMonitor` publishes real-time connectivity status with graceful offline fallbacks
7. **Global Banner System** — Auto-dismissing animated banners for success/error/info feedback and offline mode
8. **Multipart/Form-data** — Custom boundary-based upload builder for images and videos
9. **Native Socket.IO Client** — Zero-dependency Engine.IO v4 / Socket.IO v4 implementation using `URLSessionWebSocketTask`
10. **Real-Time Notifications** — Instant delivery via WebSocket with Combine event bus, auto-reconnect with exponential backoff

---

*Generated on September 25, 2026*
