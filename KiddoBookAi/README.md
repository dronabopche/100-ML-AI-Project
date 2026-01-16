# KiddoBookAI

KiddoBookAI is a playful AI-powered platform with Flutter frontend and minimalist Flask backend.  
Generate custom children's stories or get AI-powered resume feedback - all with a clean, modular design.

---

## Features

- **AI Children's Book Generation** using Remine API
- **AI Resume Roast** using Grok API  
- **Firebase Authentication** (Email & OAuth)
- **Kid-friendly Flutter Interface**
- **Lightweight Flask Backend**

---

## 🏗️ System Architecture

```mermaid
flowchart TD
    subgraph Frontend
        A[Flutter App<br/>Dart UI]
    end
    
    subgraph Backend
        B[app.py<br/>Flask Router]
    end
    
    subgraph AI_Services
        C[Remine API<br/>Book Generation]
        D[Grok API<br/>Resume Analysis]
    end
    
    subgraph Auth
        E[Firebase<br/>Authentication]
    end
    
    A -->|HTTP Requests| B
    A --> E
    B -->|Route: /generate_book| C
    B -->|Route: /roast_resume| D
```

---

## 🔄 Data Flow Sequence

```mermaid
sequenceDiagram
    participant User
    participant Flutter as Flutter App
    participant Flask as app.py (Flask)
    participant AI as AI Service
    participant Firebase as Firebase Auth

    User->>Flutter: Open App
    Flutter->>Firebase: Login
    Firebase-->>Flutter: Auth Token
    
    User->>Flutter: Select Feature & Input
    Flutter->>Flask: POST Request + Token
    
    alt Book Generation
        Flask->>Remine: Call Remine API
        Remine-->>Flask: Generated Story
    else Resume Roast
        Flask->>Grok: Call Grok API
        Grok-->>Flask: Resume Feedback
    end
    
    Flask-->>Flutter: Formatted Response
    Flutter-->>User: Display Result
```

---

## 📁 Project Structure

```mermaid
graph TD
    A[KiddoBookAI] --> B[frontend/]
    A --> C[backend/]
    
    B --> B1[lib/]
    B --> B2[assets/]
    B --> B3[pubspec.yaml]
    
    C --> C1[app.py]
    C --> C2[requirements.txt]
    C --> C3[.env]
    
    B1 --> B1a[main.dart]
    B1 --> B1b[screens/]
    B1 --> B1c[services/]
    
    B1b --> B1b1[book_screen.dart]
    B1b --> B1b2[resume_screen.dart]
    B1b --> B1b3[auth_screen.dart]
```

---

## 🎯 Backend Architecture

```mermaid
flowchart LR
    subgraph app_py
        A[Flask App] --> B[Request Handler]
        B --> C{Route Check}
        C -->|/generate_book| D[Book Module]
        C -->|/roast_resume| E[Resume Module]
        D --> F[Call Remine API]
        E --> G[Call Grok API]
        F --> H[Format Response]
        G --> H
        H --> I[Return JSON]
    end
```

---

## 🛠️ Backend Code Structure

```python
# app.py - Complete Backend
├── Flask App Setup
│   ├── CORS configuration
│   ├── Route definitions
│   └── Error handlers
├── Authentication Middleware
│   ├── Firebase token verification
│   └── User validation
├── Book Generation Route (/generate_book)
│   ├── Input validation
│   ├── Remine API call
│   ├── Response formatting
│   └── Error handling
├── Resume Roast Route (/roast_resume)
│   ├── Resume text processing
│   ├── Grok API call
│   ├── Feedback structuring
│   └── Error handling
└── Utility Functions
    ├── API key management
    ├── Rate limiting
    └── Logging
```

## 🚀 Deployment Architecture

```mermaid
flowchart LR
    A[User Devices<br/>iOS/Android/Web] --> B[Cloudflare/<br/>CDN]
    B --> C[Firebase Hosting<br/>Flutter Web]
    B --> D[Render/Vercel/<br/>Flask Backend]
    
    C --> E[Firebase Auth]
    D --> F[Remine API]
    D --> G[Grok API]
    
    style A fill:#e1f5fe
    style C fill:#f3e5f5
    style D fill:#e8f5e8
```

---

## 🔄 Request-Response Flow

```mermaid
timeline
    title API Request Lifecycle
    section Flutter App
        User Input     : Collect story parameters
        Build Request  : JSON + Auth headers
        Send           : HTTP POST to backend
    section Flask Backend
        Receive        : Validate & parse
        Authenticate   : Verify Firebase token
        Route          : To appropriate handler
        Call AI API    : Remine/Grok
        Process        : Format response
        Return         : JSON to Flutter
    section AI Service
        Process        : Generate content
        Return         : Raw AI response
```

---

## 🏗️ Component Architecture

```mermaid
graph TB
    subgraph Presentation_Layer
        P1[Flutter UI Components]
        P2[State Management]
        P3[API Client]
    end
    
    subgraph Business_Logic
        B1[app.py - Flask]
        B2[Authentication]
        B3[Request Routing]
    end
    
    subgraph Data_Layer
        D1[Remine API]
        D2[Grok API]
        D3[Firebase Auth]
    end
    
    P1 --> P3
    P3 --> B1
    B1 --> D1
    B1 --> D2
    P3 --> D3
    
    style P1 fill:#bbdefb
    style B1 fill:#c8e6c9
    style D1 fill:#ffecb3
```

## 🎨 Frontend-Backend Integration

```mermaid
graph LR
    subgraph Flutter_Frontend
        A[UI Screens] --> B[API Service]
        B --> C[HTTP Client]
    end
    
    subgraph Flask_Backend
        D[app.py] --> E[Request Handler]
        E --> F[AI Router]
    end
    
    subgraph External_Services
        G[Remine API]
        H[Grok API]
        I[Firebase]
    end
    
    C --> D
    F --> G
    F --> H
    B --> I
    
    style A fill:#e3f2fd
    style D fill:#f3e5f5
    style G fill:#f1f8e9
```

---

## Technology Stack

### 🎯 Frontend Layer
- **Flutter 3.x** - Cross-platform framework
- **Dart** - Programming language
- **Firebase Auth** - Authentication service
- **HTTP Client** - API communication

### ⚙️ Backend Layer  
- **Python Flask** - Micro web framework
- **Firebase Admin SDK** - Token verification
- **Requests** - HTTP library for API calls

### 🤖 AI Services Layer
- **Remine API** - Children's story generation
- **Grok API** - Resume analysis and feedback

### 🔧 Development Tools
- **Postman** - API testing
- **Git** - Version control
- **VS Code** - Development environment

---

## Quick Start

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/kiddobookai.git
cd kiddobookai
```

2. **Backend setup:**
```bash
cd backend
pip install -r requirements.txt
python app.py
```

3. **Frontend setup:**
```bash
cd frontend
flutter pub get
flutter run
```

---

## API Configuration

Add your API keys to `.env` file:
```env
REMINES_API_KEY=your_remine_key_here
GROK_API_KEY=your_grok_key_here
FIREBASE_CREDENTIALS=path/to/firebase.json
```

---

## 📞 Support

For issues or questions:
1. Check existing GitHub issues
2. Create new issue with detailed description
3. Email: dronabocphe@gmail.com

---

## 📄 License

MIT License - see LICENSE file for details.

---

## 👨‍💻 Author

**Drona**  
*Building playful AI experiences for everyone*  
[GitHub](https://github.com/yourusername) | [Portfolio](https://drona.dev)

---
```
<div align="center">
  
**"Where children's creativity meets professional growth"**

</div>
```
