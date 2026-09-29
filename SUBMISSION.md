## Task 1: Requirements Analysis & Prompt Architecture

### Prompt

[ROLE]
You are a Lead Systems Architect specializing in lightweight, modern full-stack web applications for academic and enterprise environments.

[CONTEXT]
A team of 4th-year BSIT students is developing a working prototype for an Online Campus Event Management System during a 3-hour laboratory examination. The system must enable students to view upcoming campus events, register for events, and allow administrators to review registered attendees.

[TASK]
Provide an overall system architecture and design overview for the Online Campus Event Management System. Your design should outline:

High-level architecture and system layers (Presentation, API/Logic, Persistence).

Core system modules and data flow for Event Browsing, Registration, and Admin Management.

Recommended technology choices suitable for rapid prototyping within 3 hours.

[CONSTRAINTS]

DO NOT use third-party global state management libraries (e.g., Redux, Zustand, MobX); stick to native React state/context or lightweight vanilla JS.

DO NOT include microservices, distributed queues, serverless functions, or complex enterprise message brokers; the solution must be a single monolithic/modular prototype.

Keep the architectural blueprint realistic, clear, and fully executable within a 3-hour team development timeframe.

---

### Output

#### System Architecture Overview: Online Campus Event Management System

##### 1. High-Level Architecture & System Layers

To achieve rapid prototyping within a strict 3-hour laboratory timeframe, the system utilizes a **Monolithic Single-Page Application (SPA) with a Modular RESTful Backend Layer**.

[ Presentation Layer ]  -->  [ API / Business Logic Layer ]  -->  [ Persistence Layer ]
React + Tailwind CSS         Express.js / Node.js Router        PostgreSQL / MySQL
(Native State / Context)     (REST Controller & Validation)     (Direct SQL / Knex)

* **Presentation Layer (Client):** Built as a React SPA using Vite for fast module updates and structured with native React state (`useState`, `useContext`) and Tailwind CSS for rapid component layout without external state libraries.
* **API / Business Logic Layer (Server):** Node.js runtime running an Express.js web server. Handles input validation (such as email domain checks and seat quota verification) and routes requests through direct REST endpoint controllers.
* **Persistence Layer (Database):** A relational database (PostgreSQL or MySQL) structured in 3rd Normal Form (3NF), accessed via direct parameterized SQL queries to maintain execution safety without heavy ORM overhead.

##### 2. Core Modules & System Data Flow

* **Event Browsing Module:**
  1. Student requests the event catalog via client interface.
  2. Frontend sends an HTTP `GET /api/events` request.
  3. API queries active events alongside real-time calculated seat availability (`capacity - count(registrations)`).
  4. Client receives JSON payload and dynamically renders accessible event cards.

* **Event Registration Module:**
  1. Student fills out and submits the event registration form with their institutional email (`@univ.edu.ph`).
  2. Server performs verification: validates the email domain format, checks for duplicate registrations, and verifies that `remaining_seats > 0`.
  3. Upon passing validation, the API executes an `INSERT INTO registrations` query and returns an HTTP `201 Created` status to the client.

* **Admin Management Module:**
  1. Admin selects a specific event to view attendees.
  2. Frontend issues an HTTP `GET /api/events/:id/attendees` request.
  3. API queries and joins records between `registrations` and `users` filtered by the requested event ID.
  4. Response is displayed on the admin dashboard in an accessible tabular format.

##### 3. Recommended Technology Stack for Rapid Prototyping (3-Hour Window)

| Component | Technology | Rationale for 3-Hour Limit |
| :--- | :--- | :--- |
| **Frontend Framework** | React + Vite | Fast setup, hot-reloading, and built-in native state management capability. |
| **Styling** | Tailwind CSS | Utility classes allow rapid UI layout and responsive design without writing custom CSS. |
| **Backend Runtime** | Node.js + Express.js | Lightweight server structure with minimal boilerplate and unified JavaScript ecosystem. |
| **Database** | SQLite / PostgreSQL | Simple setup and reliable relational structure for `users`, `events`, and `registrations`. |
| **HTTP Client** | Native `fetch` API | Zero-dependency HTTP communication for standard REST calls. |

---

### Manual Grounding Evaluation

The AI-generated architecture provides a highly realistic, grounded, and achievable design for a 3-hour laboratory timeframe. By explicitly scoping the system to a single monolithic SPA using React, Express, and standard SQL queries, the blueprint completely avoids over-engineering pitfalls like microservices or complex global state configurations. The proposed three-layer modular structure clearly separates team responsibilities across frontend, API logic, and database tasks, enabling seamless concurrent development among group members. Furthermore, using lightweight tools like Vite and Tailwind CSS ensures the group can execute a complete working prototype well within the 180-minute limit