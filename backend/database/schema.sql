-- /database/schema.sql  (SQL Server / T-SQL)
-- Timestamps are campus local time (SYSDATETIME).

CREATE TABLE dbo.EventCategories (
    category_id TINYINT      IDENTITY(1,1) NOT NULL,
    name        NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_EventCategories PRIMARY KEY CLUSTERED (category_id),
    CONSTRAINT UQ_EventCategories_Name UNIQUE (name),
    CONSTRAINT CK_EventCategories_Name CHECK (LEN(LTRIM(RTRIM(name))) > 0)
);
GO

CREATE TABLE dbo.Users (
    user_id    INT           IDENTITY(1,1) NOT NULL,
    student_id NVARCHAR(10)  NOT NULL,
    full_name  NVARCHAR(100) NOT NULL,
    email      NVARCHAR(254) NOT NULL,
    year_level NVARCHAR(10)  NOT NULL,
    program    NVARCHAR(100) NOT NULL,
    phone      NVARCHAR(15)  NULL,
    role       NVARCHAR(10)  NOT NULL CONSTRAINT DF_Users_Role DEFAULT ('Student'),
    created_at DATETIME2(0)  NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (user_id),
    CONSTRAINT UQ_Users_StudentId UNIQUE (student_id),
    CONSTRAINT UQ_Users_Email UNIQUE (email),
    CONSTRAINT CK_Users_StudentId CHECK (student_id LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT CK_Users_Email CHECK (email LIKE '%_@_%.edu' OR email LIKE '%_@_%.edu.ph'),
    CONSTRAINT CK_Users_FullName CHECK (LEN(LTRIM(RTRIM(full_name))) >= 2),
    CONSTRAINT CK_Users_Program CHECK (LEN(LTRIM(RTRIM(program))) > 0),
    CONSTRAINT CK_Users_YearLevel CHECK (year_level IN ('1st year','2nd year','3rd year','4th year','Graduate')),
    CONSTRAINT CK_Users_Phone CHECK (phone IS NULL OR (LEN(phone) >= 7 AND phone NOT LIKE '%[^0-9 +-]%')),
    CONSTRAINT CK_Users_Role CHECK (role IN ('Student','Admin'))
);
GO

CREATE TABLE dbo.Events (
    event_id    INT            IDENTITY(1,1) NOT NULL,
    title       NVARCHAR(150)  NOT NULL,
    description NVARCHAR(1000) NULL,
    category_id TINYINT        NOT NULL,
    venue       NVARCHAR(150)  NOT NULL,
    organizer   NVARCHAR(150)  NOT NULL,
    start_at    DATETIME2(0)   NOT NULL,
    end_at      DATETIME2(0)   NULL,
    capacity    INT            NOT NULL,
    created_at  DATETIME2(0)   NOT NULL CONSTRAINT DF_Events_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Events PRIMARY KEY CLUSTERED (event_id),
    CONSTRAINT FK_Events_Category FOREIGN KEY (category_id)
        REFERENCES dbo.EventCategories (category_id)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT CK_Events_Title CHECK (LEN(LTRIM(RTRIM(title))) > 0),
    CONSTRAINT CK_Events_Capacity CHECK (capacity >= 0),
    CONSTRAINT CK_Events_EndAfterStart CHECK (end_at IS NULL OR end_at > start_at)
);
GO

CREATE TABLE dbo.Registrations (
    registration_id INT           IDENTITY(1,1) NOT NULL,
    user_id         INT           NOT NULL,
    event_id        INT           NOT NULL,
    registered_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_Registrations_RegisteredAt DEFAULT (SYSDATETIME()),
    special_needs   NVARCHAR(500) NULL,
    consent_given   BIT           NOT NULL CONSTRAINT DF_Registrations_Consent DEFAULT (0),
    CONSTRAINT PK_Registrations PRIMARY KEY CLUSTERED (registration_id),
    CONSTRAINT FK_Registrations_User FOREIGN KEY (user_id)
        REFERENCES dbo.Users (user_id)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_Registrations_Event FOREIGN KEY (event_id)
        REFERENCES dbo.Events (event_id)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT UQ_Registrations_Event_User UNIQUE (event_id, user_id),
    CONSTRAINT CK_Registrations_Consent CHECK (consent_given = 1)
);
GO

-- Foreign-key indexes
CREATE NONCLUSTERED INDEX IX_Events_CategoryId      ON dbo.Events (category_id);
CREATE NONCLUSTERED INDEX IX_Registrations_UserId   ON dbo.Registrations (user_id);
-- FK index for Registrations.event_id is provided by UQ_Registrations_Event_User (event_id is its leading column).

-- Query-performance indexes
CREATE NONCLUSTERED INDEX IX_Events_StartAt
    ON dbo.Events (start_at) INCLUDE (title, category_id, venue, capacity);   -- upcoming events
GO

-- Capacity + "upcoming only" enforcement (cannot be done with a simple CHECK)
CREATE TRIGGER dbo.trg_Registrations_Enforce
ON dbo.Registrations
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Lock the affected event rows so concurrent registrations serialize.
    IF EXISTS (
        SELECT 1
        FROM dbo.Events AS e WITH (UPDLOCK, HOLDLOCK)
        WHERE e.event_id IN (SELECT event_id FROM inserted)
          AND e.start_at <= SYSDATETIME()
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Registration is closed: the event has already started.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM dbo.Events AS e WITH (UPDLOCK, HOLDLOCK)
        WHERE e.event_id IN (SELECT event_id FROM inserted)
          AND (SELECT COUNT(*) FROM dbo.Registrations AS r WHERE r.event_id = e.event_id) > e.capacity
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'Registration failed: the event is fully booked.', 1;
    END;
END;
GO

-- Reference data used by the category dropdown
INSERT INTO dbo.EventCategories (name)
VALUES (N'Academic'), (N'Sports'), (N'Arts & Culture'), (N'Career'), (N'Community');
GO