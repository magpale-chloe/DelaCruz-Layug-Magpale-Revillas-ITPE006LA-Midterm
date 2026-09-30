-- Online Campus Event Management System
-- PostgreSQL schema, 3NF relational prototype.
-- Note: PostgreSQL indexes are non-clustered (heap-based) by default.

CREATE TABLE event_categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    CONSTRAINT uq_event_categories_name UNIQUE (category_name),
    CONSTRAINT chk_event_categories_name_not_blank CHECK (btrim(category_name) <> '')
);

INSERT INTO event_categories (category_name)
VALUES ('Academic'), ('Sports'), ('Arts & Culture'), ('Career'), ('Community');

CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_number VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    year_level VARCHAR(20),
    program VARCHAR(150),
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'STUDENT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_student_number UNIQUE (student_number),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_role CHECK (role IN ('STUDENT', 'ADMIN')),
    CONSTRAINT chk_users_names_not_blank CHECK (
        btrim(first_name) <> '' AND btrim(last_name) <> ''
    ),
    CONSTRAINT chk_users_email_format CHECK (
        email ~* '^[^\s@]+@[^\s@]+\.edu(\.[a-z]{2})?$'
    ),
    CONSTRAINT chk_users_student_number_format CHECK (
        student_number IS NULL OR student_number ~ '^\d{4}-\d{5}$'
    ),
    CONSTRAINT chk_users_student_number_required_for_students CHECK (
        role <> 'STUDENT' OR student_number IS NOT NULL
    ),
    CONSTRAINT chk_users_year_level CHECK (
        year_level IS NULL
        OR year_level IN ('1st year', '2nd year', '3rd year', '4th year', 'Graduate')
    ),
    CONSTRAINT chk_users_phone_format CHECK (
        phone IS NULL OR phone ~ '^[+\d][\d\s-]{6,14}$'
    )
);

CREATE TABLE events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id BIGINT NOT NULL,
    event_title VARCHAR(200) NOT NULL,
    event_description TEXT,
    venue VARCHAR(150) NOT NULL,
    organizer_name VARCHAR(150) NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    registration_deadline TIMESTAMPTZ NOT NULL,
    capacity INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PUBLISHED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_events_category
        FOREIGN KEY (category_id)
        REFERENCES event_categories (category_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_events_title_not_blank CHECK (btrim(event_title) <> ''),
    CONSTRAINT chk_events_venue_not_blank CHECK (btrim(venue) <> ''),
    CONSTRAINT chk_events_organizer_not_blank CHECK (btrim(organizer_name) <> ''),
    CONSTRAINT chk_events_capacity_positive CHECK (capacity > 0),
    CONSTRAINT chk_events_schedule CHECK (
        registration_deadline < starts_at AND starts_at < ends_at
    ),
    CONSTRAINT chk_events_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'CANCELLED'))
);

CREATE TABLE registrations (
    registration_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
    special_needs TEXT,
    registered_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_registrations_user_event UNIQUE (user_id, event_id),
    CONSTRAINT fk_registrations_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_registrations_event
        FOREIGN KEY (event_id)
        REFERENCES events (event_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Non-clustered indexes on foreign key columns.
-- registrations.user_id is already indexed: it is the leading column of
-- uq_registrations_user_event, so a separate index would be redundant.
CREATE INDEX ix_events_category_id ON events (category_id);
CREATE INDEX ix_registrations_event_id ON registrations (event_id);
CREATE INDEX ix_events_upcoming ON events (status, starts_at);

CREATE OR REPLACE FUNCTION enforce_registration_rules()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    event_capacity INTEGER;
    event_status VARCHAR(20);
    event_deadline TIMESTAMPTZ;
    current_registration_count INTEGER;
BEGIN
    -- Lock the event row so concurrent registrations serialize.
    SELECT capacity, status, registration_deadline
    INTO event_capacity, event_status, event_deadline
    FROM events
    WHERE event_id = NEW.event_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event % does not exist.', NEW.event_id
            USING ERRCODE = '23503';
    END IF;

    IF event_status <> 'PUBLISHED' THEN
        RAISE EXCEPTION 'Event % is not open for registration (status: %).', NEW.event_id, event_status
            USING ERRCODE = '23514';
    END IF;

    IF CURRENT_TIMESTAMP > event_deadline THEN
        RAISE EXCEPTION 'Registration for event % closed at %.', NEW.event_id, event_deadline
            USING ERRCODE = '23514';
    END IF;

    SELECT COUNT(*)
    INTO current_registration_count
    FROM registrations
    WHERE event_id = NEW.event_id;

    IF TG_OP = 'UPDATE' AND OLD.event_id = NEW.event_id THEN
        current_registration_count := current_registration_count - 1;
    END IF;

    IF current_registration_count >= event_capacity THEN
        RAISE EXCEPTION 'Event % has reached its maximum capacity of %.', NEW.event_id, event_capacity
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_registrations_enforce_rules
BEFORE INSERT OR UPDATE OF event_id
ON registrations
FOR EACH ROW
EXECUTE FUNCTION enforce_registration_rules();

CREATE OR REPLACE FUNCTION prevent_event_capacity_below_registrations()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    registration_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO registration_count
    FROM registrations
    WHERE event_id = OLD.event_id;

    IF NEW.capacity < registration_count THEN
        RAISE EXCEPTION 'Event % already has % registrations and cannot be reduced below that number.', OLD.event_id, registration_count
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_events_prevent_capacity_reduction
BEFORE UPDATE OF capacity
ON events
FOR EACH ROW
EXECUTE FUNCTION prevent_event_capacity_below_registrations();