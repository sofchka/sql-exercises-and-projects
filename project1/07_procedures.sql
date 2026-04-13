USE coding_challenge_platform;

DROP PROCEDURE IF EXISTS sp_create_submission;
DROP PROCEDURE IF EXISTS sp_get_user_score;
DROP PROCEDURE IF EXISTS sp_get_user_activity;
DROP PROCEDURE IF EXISTS sp_get_challenge_summary;
DROP PROCEDURE IF EXISTS sp_reassign_pixel;

DELIMITER $$

-- A reusable entry point for application-side submission creation.
CREATE PROCEDURE sp_create_submission(
    IN p_user_id INT,
    IN p_challenge_id INT,
    IN p_code TEXT,
    IN p_language VARCHAR(20),
    IN p_result VARCHAR(25),
    IN p_execution_time_ms DECIMAL(8,2),
    IN p_memory_kb INT,
    IN p_submitted_at DATETIME
)
BEGIN
    INSERT INTO submissions (
        user_id,
        challenge_id,
        code,
        language,
        result,
        execution_time_ms,
        memory_kb,
        submitted_at
    )
    VALUES (
        p_user_id,
        p_challenge_id,
        p_code,
        p_language,
        p_result,
        p_execution_time_ms,
        p_memory_kb,
        p_submitted_at
    );
END$$

-- Separate aggregate subqueries keep submission counts and owned-pixel counts accurate.
CREATE PROCEDURE sp_get_user_score(IN p_user_id INT)
BEGIN
    SELECT
        u.user_id,
        u.username,
        COALESCE(s.accepted_submissions, 0) AS accepted_submissions,
        COALESCE(s.total_submissions, 0) AS total_submissions,
        COALESCE(p.owned_pixels, 0) AS owned_pixels
    FROM users AS u
    LEFT JOIN (
        SELECT
            user_id,
            SUM(CASE WHEN result = 'Accepted' THEN 1 ELSE 0 END) AS accepted_submissions,
            COUNT(*) AS total_submissions
        FROM submissions
        GROUP BY user_id
    ) AS s ON s.user_id = u.user_id
    LEFT JOIN (
        SELECT
            owner_user_id AS user_id,
            COUNT(*) AS owned_pixels
        FROM pixels
        WHERE owner_user_id IS NOT NULL
        GROUP BY owner_user_id
    ) AS p ON p.user_id = u.user_id
    WHERE u.user_id = p_user_id;
END$$

-- Ordered newest-first so dashboards can display recent user activity immediately.
CREATE PROCEDURE sp_get_user_activity(IN p_user_id INT)
BEGIN
    SELECT
        s.submission_id,
        c.title AS challenge_title,
        s.language,
        s.result,
        s.execution_time_ms,
        s.memory_kb,
        s.submitted_at
    FROM submissions AS s
    JOIN challenges AS c ON c.challenge_id = s.challenge_id
    WHERE s.user_id = p_user_id
    ORDER BY s.submitted_at DESC, s.submission_id DESC;
END$$

-- Combines challenge performance and canvas progress in one procedure result.
CREATE PROCEDURE sp_get_challenge_summary(IN p_challenge_id INT)
BEGIN
    SELECT
        c.challenge_id,
        c.title,
        c.difficulty,
        COALESCE(s.total_submissions, 0) AS total_submissions,
        COALESCE(s.accepted_submissions, 0) AS accepted_submissions,
        s.fastest_accepted_execution_time_ms,
        COALESCE(p.total_pixels, 0) AS total_pixels,
        COALESCE(p.claimed_pixels, 0) AS claimed_pixels
    FROM challenges AS c
    LEFT JOIN (
        SELECT
            challenge_id,
            COUNT(*) AS total_submissions,
            SUM(CASE WHEN result = 'Accepted' THEN 1 ELSE 0 END) AS accepted_submissions,
            MIN(CASE WHEN result = 'Accepted' THEN execution_time_ms END) AS fastest_accepted_execution_time_ms
        FROM submissions
        GROUP BY challenge_id
    ) AS s ON s.challenge_id = c.challenge_id
    LEFT JOIN (
        SELECT
            challenge_id,
            COUNT(*) AS total_pixels,
            SUM(CASE WHEN owner_user_id IS NOT NULL THEN 1 ELSE 0 END) AS claimed_pixels
        FROM pixels
        GROUP BY challenge_id
    ) AS p ON p.challenge_id = c.challenge_id
    WHERE c.challenge_id = p_challenge_id;
END$$

-- History is not inserted manually here because the pixel update trigger records it automatically.
CREATE PROCEDURE sp_reassign_pixel(
    IN p_pixel_id INT,
    IN p_new_owner_user_id INT,
    IN p_submission_id INT,
    IN p_new_color CHAR(7)
)
BEGIN
    UPDATE pixels
    SET owner_user_id = p_new_owner_user_id,
        acquired_submission_id = p_submission_id,
        color = p_new_color
    WHERE pixel_id = p_pixel_id;
END$$

DELIMITER ;
