## Task 1: Requirements Analysis & Prompt Architecture

### 1. Production-Grade RCTC Prompt

```text
[ROLE]
You are a Lead Systems Architect designing lightweight, secure web applications for academic institutions.

[CONTEXT]
A team of fourth-year BSIT students has built a prototype Online Campus Event Management System within a three-hour laboratory examination. The project contains a static vanilla HTML/CSS/JavaScript frontend, an Express.js and Node.js backend, and a PostgreSQL relational database. Students must browse upcoming events, search and filter the catalog, submit registrations with validated student details and consent, and view registrations created during the current browser session. The backend must calculate available seats, prevent duplicate registrations, enforce event capacity and registration deadlines, and provide an administrator endpoint for viewing attendees.

[TASK]
Produce an overall system design for this prototype. Describe the presentation, API/business-logic, and persistence layers; frontend modules and data flow; backend API endpoints; database entities, relationships, constraints, indexes, and transaction rules; and security, accessibility, and concurrency considerations.

[CONSTRAINTS]
- Use the existing stack: vanilla HTML/CSS/JavaScript, Node.js, Express.js, PostgreSQL, and native fetch.
- Do not replace the frontend with React, Tailwind, or another framework.
- Do not use Redux, Zustand, MobX, or any third-party global state-management library.
- Do not introduce microservices, queues, serverless functions, or other enterprise infrastructure.
- Use parameterized SQL queries and server-side validation; never expose database credentials in client-side code or documentation.
- Treat frontend validation as user feedback only; the backend and database must enforce registration rules.
- Keep the design realistic and implementable by a four-person team within three hours.
```

### 2. AI Output

#### System Design: Online Campus Event Management System

The system is a small monolithic web application with three layers:

```text
[ Vanilla HTML/CSS/JavaScript frontend ]
                    |
              Native fetch API
                    |
[ Express.js REST API and validation logic ]
                    |
[ PostgreSQL database with constraints and triggers ]
```

The presentation layer serves static files from `frontend`. It renders event cards, search and category filtering, the registration form, validation messages, confirmation feedback, and a current-session registration table. The API layer is an Express.js server exposing `GET /api/events`, `POST /api/registrations`, and `GET /api/admin/events/:id/registrations`. The persistence layer is PostgreSQL, protected by parameterized queries, foreign keys, unique constraints, check constraints, indexes, and triggers.

The event catalog loads upcoming events with category, schedule, venue, organizer, description, and calculated remaining seats. The registration form validates the selected event, full name, `YYYY-NNNNN` student ID, `.edu` or `.edu.ph` email, year level, program, optional phone number, and required consent. On submission, the frontend sends the event ID and student details to the API, displays the returned reference or an error, and refreshes the event list. Session registration summaries are kept in browser memory, while successful API submissions persist in PostgreSQL. The admin endpoint joins users and registrations to provide attendee details, but requires authentication and authorization before production use.

The database contains `event_categories`, `users`, `events`, and `registrations`. Categories classify events; users make registrations; and events receive registrations. The schema enforces valid student numbers, email addresses, year levels, phone numbers, roles, event schedules, and capacities. A unique `(user_id, event_id)` constraint prevents duplicate registration. A registration trigger locks the event row, checks publication status and registration deadline, counts current registrations, and rejects attempts to exceed capacity. A second trigger prevents capacity from being reduced below existing registrations.

Security and quality safeguards include environment-only database credentials, parameterized SQL, server-side validation, escaped dynamic HTML or DOM `textContent` for user-controlled values, semantic labels and fieldsets, keyboard focus handling, live status messages, and a skip link. Transactions and row locking prevent concurrent registrations from oversubscribing an event. Administrator authentication and production secret rotation remain required before deployment.

### 3. Manual Grounding Evaluation

The generated design is realistic for a three-hour prototype because it matches the implemented vanilla HTML/CSS/JavaScript frontend, Express.js API, PostgreSQL schema, and native `fetch` approach instead of introducing an unimplemented framework. It correctly assigns seat availability, duplicate-registration prevention, deadlines, consent, and concurrency protection to the backend and database rather than relying only on browser checks. The design is achievable for a four-person team because the modules and three API endpoints are small, while database constraints and triggers provide important safeguards without additional infrastructure. Administrator authentication and production secret management remain necessary follow-up work before deployment beyond the prototype.

---

## Task 5: Group Integration & Verification Report

### 1. Team Roster

| Group member               | Assigned role                               |
|----------------------------|---------------------------------------------|
| Dela Cruz                  | Systems Architect & Prompt Leader           |
| Layug                      | QA & Security Engineer                      |
| Magpale, Precious Chloe L. | Frontend Engineer                           |
| Revillas                   | Database & Backend Engineer                 |

### 2. Setup Instructions

1. Ensure Node.js and PostgreSQL are installed.
2. From the directory containing `server.js`, install the backend dependencies with `npm install`.
3. Create a local environment file named `.env` and set `DATABASE_URL` to the PostgreSQL connection string. Do not commit this file or include its credentials in the submission.
4. Apply the PostgreSQL schema from `database/schema.sql` to the configured database.
5. Start the application with `node server.js`.
6. Open `http://localhost:3000` in a browser to view the event catalog and registration form.

The frontend can also be inspected directly from `frontend/index.html`, but API-backed event loading and registration require the Express server and database connection.

### 3. AI Disclosure Statement

The team used GitHub Copilot and an AI assistant to help draft the initial system architecture, frontend structure, validation logic, database design, and documentation. All generated output was manually reviewed against the actual project files, tested through the registration and event-browsing flows, and revised by team members. The team retained only code and documentation that matched the implemented vanilla JavaScript, Express.js, PostgreSQL, and accessibility requirements.

### 4. Group Verification Log

| # 
| AI-generated output or issue 
| Manual correction or refinement 
| Reason and Member Responsible 

| 2 |
| Unsafe dynamic HTML rendering used interpolated event and registration values in `innerHTML`. 
| Replaced untrusted value interpolation with `createElement()` and `textContent` where appropriate, and added escaping for values that remain in trusted templates. 
| Prevents cross-site scripting when event or registration data contains HTML or JavaScript. 
| Magpale

| 2 |
| The initial frontend treated local event data, seat counts, and random reference numbers as authoritative and could appear to complete a registration without the server. 
| Refined the frontend to load events through `GET /api/events` and submit registrations through `POST /api/registrations`, then display the server response and refresh event data. 
| Prevents fake or stale registrations and makes the database the source of truth. 
| Magpale

| 3 |          
| A basic registration design could rely only on client-side checks for duplicate registrations, event deadlines, and seat capacity. 
| Added database unique constraints, server-side parameterized queries, a transaction, row locking, and PostgreSQL triggers that reject duplicate, closed, unpublished, or over-capacity registrations. 
| Protects business rules from modified requests and concurrent submissions. 
| Revillas. 
