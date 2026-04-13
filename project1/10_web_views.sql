USE coding_challenge_platform;

-- ============================================
-- WEB VIEWS
-- Flat, ready-to-use views for the frontend.
-- Backend can SELECT * FROM these directly.
-- ============================================

DROP VIEW IF EXISTS vw_web_leaderboard;
DROP VIEW IF EXISTS vw_web_canvas;
DROP VIEW IF EXISTS vw_web_recent_activity;
DROP VIEW IF EXISTS vw_web_challenge_list;
DROP VIEW IF EXISTS vw_web_user_stats;

-- ============================================
-- 1. vw_web_leaderboard
--    Used by: Statistics page
--    Shows ranking of all users
-- ============================================
CREATE VIEW vw_web_leaderboard AS
SELECT
    u.user_id,
    u.username,
    COALESCE(s.accepted_submissions, 0) AS accepted_submissions,
    COALESCE(s.total_submissions, 0)    AS total_submissions,
    COALESCE(p.owned_pixels, 0)         AS owned_pixels,
    RANK() OVER (
        ORDER BY COALESCE(s.accepted_submissions, 0) DESC,
                 COALESCE(p.owned_pixels, 0) DESC
    ) AS leaderboard_rank
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
    SELECT owner_user_id AS user_id, COUNT(*) AS owned_pixels
    FROM pixels
    WHERE owner_user_id IS NOT NULL
    GROUP BY owner_user_id
) AS p ON p.user_id = u.user_id;


-- ============================================
-- 2. vw_web_canvas
--    Used by: PixelCanvas page
--    Full pixel grid with owner info
-- ============================================
CREATE VIEW vw_web_canvas AS
SELECT
    px.pixel_id,
    px.challenge_id,
    c.title         AS challenge_title,
    px.x_coordinate,
    px.y_coordinate,
    px.color,
    px.owner_user_id,
    u.username      AS owner_username,
    px.last_updated
FROM pixels AS px
JOIN challenges AS c ON c.challenge_id = px.challenge_id
LEFT JOIN users AS u  ON u.user_id = px.owner_user_id;


-- ============================================
-- 3. vw_web_recent_activity
--    Used by: PixelCanvas live feed
--    Last 50 pixel ownership changes
-- ============================================
CREATE VIEW vw_web_recent_activity AS
SELECT
    ph.history_id,
    ph.pixel_id,
    c.title         AS challenge_title,
    prev_u.username AS previous_owner,
    new_u.username  AS new_owner,
    ph.color_before,
    ph.color_after,
    ph.change_type,
    ph.changed_at
FROM pixel_history AS ph
JOIN challenges AS c   ON c.challenge_id = ph.challenge_id
LEFT JOIN users prev_u ON prev_u.user_id = ph.previous_owner_user_id
LEFT JOIN users new_u  ON new_u.user_id  = ph.new_owner_user_id
ORDER BY ph.changed_at DESC
LIMIT 50;


-- ============================================
-- 4. vw_web_challenge_list
--    Used by: any page listing challenges
--    Includes attempt counts for display
-- ============================================
CREATE VIEW vw_web_challenge_list AS
SELECT
    c.challenge_id,
    c.title,
    c.slug,
    c.difficulty,
    c.reward_pixels,
    COALESCE(s.total_attempts, 0)    AS total_attempts,
    COALESCE(s.accepted_attempts, 0) AS accepted_attempts,
    COALESCE(p.total_pixels, 0)      AS total_pixels,
    COALESCE(p.claimed_pixels, 0)    AS claimed_pixels
FROM challenges AS c
LEFT JOIN (
    SELECT
        challenge_id,
        COUNT(*) AS total_attempts,
        SUM(CASE WHEN result = 'Accepted' THEN 1 ELSE 0 END) AS accepted_attempts
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
ORDER BY c.challenge_id;


-- ============================================
-- 5. vw_web_user_stats
--    Used by: Profile page
--    One row per user with all stats
-- ============================================
CREATE VIEW vw_web_user_stats AS
SELECT
    u.user_id,
    u.username,
    u.email,
    u.created_at,
    COALESCE(s.total_submissions, 0)    AS total_submissions,
    COALESCE(s.accepted_submissions, 0) AS accepted_submissions,
    COALESCE(p.owned_pixels, 0)         AS owned_pixels
FROM users AS u
LEFT JOIN (
    SELECT
        user_id,
        COUNT(*) AS total_submissions,
        SUM(CASE WHEN result = 'Accepted' THEN 1 ELSE 0 END) AS accepted_submissions
    FROM submissions
    GROUP BY user_id
) AS s ON s.user_id = u.user_id
LEFT JOIN (
    SELECT owner_user_id AS user_id, COUNT(*) AS owned_pixels
    FROM pixels
    WHERE owner_user_id IS NOT NULL
    GROUP BY owner_user_id
) AS p ON p.user_id = u.user_id;
