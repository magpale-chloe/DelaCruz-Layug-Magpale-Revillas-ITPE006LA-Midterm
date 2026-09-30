const express = require("express");
const cors = require("cors");
const pool = require("./db");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// GET /api/events - upcoming events with remaining seats (derived).
// Column aliases keep the JSON names your index.html already expects.
app.get("/api/events", async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                e.event_id,
                e.title       AS event_title,
                e.description AS event_description,
                e.venue,
                e.start_at    AS starts_at,
                e.end_at      AS ends_at,
                e.capacity,
                (e.capacity - (SELECT COUNT(*) FROM registrations r
                               WHERE r.event_id = e.event_id))::int AS seats_remaining,
                (e.start_at > now()) AS registration_open
            FROM events e
            WHERE e.start_at > now()
            ORDER BY e.start_at ASC
        `);
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to retrieve events." });
    }
});

// POST /api/registrations - register a student for an event
app.post("/api/registrations", async (req, res) => {
    const { studentId, fullName, email, year, program, phone, needs, eventId } = req.body;

    if (!studentId || !fullName || !email || !year || !program || !eventId) {
        return res.status(400).json({ error: "All required fields must be provided." });
    }

    const client = await pool.connect();
    try {
        await client.query("BEGIN");

        // Create the user if new; never overwrite an existing student's details
        const userResult = await client.query(
            `INSERT INTO users (student_id, full_name, email, year_level, program, phone)
             VALUES ($1, $2, $3, $4, $5, $6)
             ON CONFLICT (student_id)
             DO UPDATE SET student_id = EXCLUDED.student_id
             RETURNING user_id`,
            [studentId, String(fullName).trim(), email, year, String(program).trim(), phone || null]
        );

        const registrationResult = await client.query(
            `INSERT INTO registrations (user_id, event_id, special_needs, consent_given)
             VALUES ($1, $2, $3, true)
             RETURNING registration_id, registered_at`,
            [userResult.rows[0].user_id, eventId, needs || null]
        );

        await client.query("COMMIT");

        res.status(201).json({
            message: "Registration successful.",
            registrationId: registrationResult.rows[0].registration_id,
            registeredAt: registrationResult.rows[0].registered_at
        });
    } catch (error) {
        await client.query("ROLLBACK").catch(() => {});
        console.error(error);

        if (error.code === "U0002") return res.status(409).json({ error: "This event is fully booked." });
        if (error.code === "U0001") return res.status(409).json({ error: "Registration is closed for this event." });
        if (error.code === "23505" && error.constraint === "uq_registrations_event_user") {
            return res.status(409).json({ error: "You are already registered for this event." });
        }
        if (error.code === "23505") {
            return res.status(409).json({ error: "That email is already used by another student." });
        }
        if (error.code === "23514") {
            return res.status(400).json({ error: "Some details are invalid. Please check the form." });
        }
        if (error.code === "23503") {
            return res.status(404).json({ error: "The selected event does not exist." });
        }
        res.status(500).json({ error: "Registration failed." });
    } finally {
        client.release();
    }
});

// GET /api/events/:eventId/attendees - admin view of registered attendees
app.get("/api/events/:eventId/attendees", async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT r.registration_id, u.student_id, u.full_name, u.email,
                    u.year_level, u.program, r.special_needs, r.registered_at
             FROM registrations r
             INNER JOIN users u ON r.user_id = u.user_id
             WHERE r.event_id = $1
             ORDER BY r.registered_at ASC`,
            [req.params.eventId]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to retrieve attendees." });
    }
});

app.get("/api/health", (req, res) => {
    res.json({ status: "OK", message: "Campus Event API is running." });
});

app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});