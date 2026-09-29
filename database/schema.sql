-- Online Campus Event Management System
-- PostgreSQL schema for a simple 3NF relational prototype.

CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_number VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'STUDENT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_student_number UNIQUE (student_number),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_role CHECK (role IN ('STUDENT', 'ADMIN')),
    CONSTRAINT chk_users_names_not_blank CHECK (
        btrim(first_name) <> ''
        AND btrim(last_name) <> ''
    ),
    CONSTRAINT chk_users_email_not_blank CHECK (btrim(email) <> ''),
    CONSTRAINT chk_users_student_number_not_blank CHECK (
        student_number IS NULL OR btrim(student_number) <> ''
    ),
    CONSTRAINT chk_users_student_number_required_for_students CHECK (
        role <> 'STUDENT' OR student_number IS NOT NULL
    )
);

CREATE TABLE events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_title VARCHAR(200) NOT NULL,
    event_description TEXT,
    venue VARCHAR(150) NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    registration_deadline TIMESTAMPTZ NOT NULL,
    capacity INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PUBLISHED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_events_title_not_blank CHECK (btrim(event_title) <> ''),
    CONSTRAINT chk_events_venue_not_blank CHECK (btrim(venue) <> ''),
    CONSTRAINT chk_events_capacity_positive CHECK (capacity > 0),
    CONSTRAINT chk_events_schedule CHECK (
        registration_deadline < starts_at
        AND starts_at < ends_at
    ),
    CONSTRAINT chk_events_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'CANCELLED'))
);

CREATE TABLE registrations (
    registration_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
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

CREATE INDEX ix_events_upcoming
    ON events (status, starts_at);

CREATE INDEX ix_registrations_user_id
    ON registrations (user_id);

CREATE INDEX ix_registrations_event_id
    ON registrations (event_id);

CREATE OR REPLACE FUNCTION enforce_registration_capacity()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    event_capacity INTEGER;
    current_registration_count INTEGER;
BEGIN
    -- Lock the event row so concurrent registrations for the same event serialize.
    SELECT capacity
    INTO event_capacity
    FROM events
    WHERE event_id = NEW.event_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event % does not exist.', NEW.event_id
            USING ERRCODE = '23503';
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

CREATE TRIGGER trg_registrations_enforce_capacity
BEFORE INSERT OR UPDATE OF event_id
ON registrations
FOR EACH ROW
EXECUTE FUNCTION enforce_registration_capacity();

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