USE coding_challenge_platform;

DROP VIEW IF EXISTS vw_leaderboard;
DROP VIEW IF EXISTS vw_user_submission_history;
DROP VIEW IF EXISTS vw_challenge_performance;
DROP VIEW IF EXISTS vw_pixel_ownership;
DROP VIEW IF EXISTS vw_pixel_history;
DROP VIEW IF EXISTS vw_submission_test_results;

-- Aggregate submissions and pixel ownership separately to avoid inflated counts from many-to-many joins.
CREATE VIEW vw_leaderboard AS
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
) AS p ON p.user_id = u.user_id;

-- This is the main reporting view for user activity across challenges.
CREATE VIEW vw_user_submission_history AS
SELECT
    s.submission_id,
    u.username,
    c.title AS challenge_title,
    s.language,
    s.result,
    s.execution_time_ms,
    s.memory_kb,
    s.submitted_at
FROM submissions AS s
JOIN users AS u ON u.user_id = s.user_id
JOIN challenges AS c ON c.challenge_id = s.challenge_id;

CREATE VIEW vw_challenge_performance AS
SELECT
    c.challenge_id,
    c.title,
    c.difficulty,
    COUNT(s.submission_id) AS total_attempts,
    SUM(CASE WHEN s.result = 'Accepted' THEN 1 ELSE 0 END) AS accepted_attempts,
    MIN(CASE WHEN s.result = 'Accepted' THEN s.execution_time_ms END) AS fastest_accepted_execution_time_ms
FROM challenges AS c
LEFT JOIN submissions AS s ON s.challenge_id = c.challenge_id
GROUP BY c.challenge_id, c.title, c.difficulty;

-- LEFT JOIN keeps unclaimed pixels visible in ownership reports.
CREATE VIEW vw_pixel_ownership AS
SELECT
    p.pixel_id,
    p.challenge_id,
    c.title AS challenge_title,
    p.x_coordinate,
    p.y_coordinate,
    p.color,
    u.username AS owner_username,
    p.last_updated
FROM pixels AS p
JOIN challenges AS c ON c.challenge_id = p.challenge_id
LEFT JOIN users AS u ON u.user_id = p.owner_user_id;

-- Usernames are resolved here so history can be presented without extra joins in application queries.
CREATE VIEW vw_pixel_history AS
SELECT
    ph.history_id,
    ph.pixel_id,
    c.title AS challenge_title,
    prev_u.username AS previous_owner_username,
    new_u.username AS new_owner_username,
    ph.color_before,
    ph.color_after,
    ph.change_type,
    ph.changed_at
FROM pixel_history AS ph
JOIN challenges AS c ON c.challenge_id = ph.challenge_id
LEFT JOIN users AS prev_u ON prev_u.user_id = ph.previous_owner_user_id
LEFT JOIN users AS new_u ON new_u.user_id = ph.new_owner_user_id;

-- This view ties test-level results back to the submission and challenge they belong to.
CREATE VIEW vw_submission_test_results AS
SELECT
    str.submission_test_result_id,
    s.submission_id,
    c.title AS challenge_title,
    tc.test_case_id,
    str.status,
    str.execution_time_ms,
    str.created_at
FROM submission_test_results AS str
JOIN submissions AS s ON s.submission_id = str.submission_id
JOIN challenges AS c ON c.challenge_id = s.challenge_id
JOIN test_cases AS tc ON tc.test_case_id = str.test_case_id;
