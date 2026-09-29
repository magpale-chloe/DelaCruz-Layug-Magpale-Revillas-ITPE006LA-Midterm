ROLE:
Act as a Senior Database Engineer and Backend Architect with expertise in relational database design, SQL, database normalization, data integrity, and production-ready backend systems.

CONTEXT:
We are building a working prototype of an Online Campus Event Management System for a 4th-year BSIT group laboratory examination.

The system must allow:
1. Students to view upcoming campus events.
2. Students to register for an event.
3. Administrators to view registered attendees.

The database must use a relational SQL database and follow Third Normal Form (3NF). The prototype will be developed within a limited 3-hour examination period, so the design must remain simple, practical, and implementable.

TASK:
Design the complete database structure for the Online Campus Event Management System.

At minimum, include these relational entities:
- Users
- Events
- Registrations

You may introduce additional entities only when they are genuinely necessary to maintain proper normalization and data integrity.

For each table, provide:
- Table name
- Column names
- Appropriate SQL data types
- Primary key
- Foreign keys
- NOT NULL constraints where appropriate
- UNIQUE constraints where appropriate
- CHECK constraints where appropriate
- Sensible default values where appropriate

Database relationships must correctly represent:
- One user can register for many events.
- One event can have many registrations.
- Each registration belongs to exactly one user and one event.

3NF REQUIREMENTS:
- Ensure every table satisfies Third Normal Form.
- Avoid repeating groups and multivalued attributes.
- Avoid storing the same piece of information unnecessarily in multiple tables.
- Ensure non-key attributes depend on the key, the whole key, and nothing but the key.
- Briefly explain why the resulting schema satisfies 3NF.

MERMAID ERD:
Generate an Entity-Relationship Diagram using Mermaid.js `erDiagram` syntax.

The Mermaid ERD must:
- Include every table in the final schema.
- Show primary keys using `PK`.
- Show foreign keys using `FK`.
- Show appropriate relationships and cardinalities.
- Match the SQL schema exactly.
- Be directly copy-pasteable into a Markdown file.

SQL DDL REQUIREMENTS:
Generate a production-grade SQL DDL script that can be saved as:

/database/schema.sql

The SQL script must include:
1. CREATE TABLE statements.
2. Primary key definitions.
3. Foreign key definitions.
4. Appropriate ON DELETE and ON UPDATE rules.
5. NOT NULL constraints.
6. UNIQUE constraints where appropriate.
7. CHECK constraints for important business rules.
8. Non-clustered indexes on all foreign key columns.
9. Additional useful indexes for common queries, such as:
   - upcoming events
   - event registrations
   - looking up registrations by user
10. A UNIQUE constraint or equivalent protection against duplicate registration of the same user for the same event.
11. Appropriate handling of event seat capacity so that registrations cannot logically exceed the event's available capacity.
12. Avoid storing calculated or redundant values when they can be derived safely from existing data.

IMPORTANT:
- Do not use NoSQL.
- Do not use unnecessary tables or over-engineer the schema.
- Do not add features outside the stated Online Campus Event Management System requirements.
- Do not use deprecated SQL practices.
- Do not hard-code passwords, connection strings, or credentials.
- Do not create foreign keys without corresponding indexes.
- Do not create an ERD that differs from the SQL schema.
- Do not assume application-level validation is enough for database integrity; enforce important rules using database constraints where practical.
- Keep the solution appropriate for a beginner/intermediate 4th-year BSIT prototype that must be implemented within the examination time limit.

OUTPUT FORMAT:
Return the answer in exactly these sections:

## 1. Database Design Overview
Briefly explain the purpose of each table and the relationships.

## 2. 3NF Validation
Explain in a concise but technically correct manner why the schema satisfies 1NF, 2NF, and 3NF.

## 3. Mermaid.js ERD
Provide ONLY a Mermaid `erDiagram` code block that can be copied directly into SUBMISSION.md.

## 4. SQL DDL Script
Provide ONLY the complete SQL script inside a `sql` code block that can be saved directly as `/database/schema.sql`.

## 5. Constraint and Index Checklist
List every:
- Primary key
- Foreign key
- CHECK constraint
- UNIQUE constraint
- Foreign-key index
- Additional performance index

Verify that every item in this checklist actually exists in the SQL script.

## 6. Manual Verification Points
Identify at least 3 things that a student should manually verify or potentially correct in the AI-generated output before submitting it. Focus on possible issues such as incorrect cardinality, missing indexes, inconsistent constraints, incorrect SQL syntax, or business rules that cannot be fully enforced using a simple CHECK constraint.