USE coding_challenge_platform;

-- ============================================
-- AUTH PROCEDURES
-- Used by the frontend for login and signup
-- ============================================

DROP PROCEDURE IF EXISTS sp_register;
DROP PROCEDURE IF EXISTS sp_login;
DROP PROCEDURE IF EXISTS sp_get_profile;
DROP PROCEDURE IF EXISTS sp_get_leaderboard;
DROP PROCEDURE IF EXISTS sp_get_canvas;
DROP PROCEDURE IF EXISTS sp_get_pixel_history;

DELIMITER $$

-- ============================================
-- 1. REGISTER (Signup page)
--    Called when user fills in signup form.
--    Returns new user_id + username so the
--    frontend can store them in localStorage.
-- ============================================
CREATE PROCEDURE sp_register(
    IN p_username    VARCHAR(50),
    IN p_email       VARCHAR(100),
    IN p_password_hash VARCHAR(255)
)
BEGIN
    -- block duplicate usernames/emails with a clear message
    IF EXISTS (SELECT 1 FROM users WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Username already taken.';
    END IF;

    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already registered.';
    END IF;

    INSERT INTO users (username, email, password_hash)
    VALUES (p_username, p_email, p_password_hash);

    -- return the new user so frontend can log them in immediately
    SELECT
        LAST_INSERT_ID() AS user_id,
        p_username       AS username,
        p_email          AS email;
END$$


-- ============================================
-- 2. LOGIN (Login page)
--    Checks credentials and returns user row.
--    Returns empty result if wrong password.
--    Frontend checks if result has rows.
-- ============================================
CREATE PROCEDURE sp_login(
    IN p_username      VARCHAR(50),
    IN p_password_hash VARCHAR(255)
)
BEGIN
    SELECT
        user_id,
        username,
        email,
        created_at
    FROM users
    WHERE username      = p_username
      AND password_hash = p_password_hash
    LIMIT 1;
END$$


-- ============================================
-- 3. GET PROFILE (Profile page)
--    Returns user info + accepted submissions
--    + owned pixels for the profile screen.
-- ============================================
CREATE PROCEDURE sp_get_profile(IN p_user_id INT)
BEGIN
    -- basic user info
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
            COUNT(*)                                              AS total_submissions,
            SUM(CASE WHEN result = 'Accepted' THEN 1 ELSE 0 END) AS accepted_submissions
        FROM submissions
        GROUP BY user_id
    ) AS s ON s.user_id = u.user_id
    LEFT JOIN (
        SELECT owner_user_id AS user_id, COUNT(*) AS owned_pixels
        FROM pixels
        WHERE owner_user_id IS NOT NULL
        GROUP BY owner_user_id
    ) AS p ON p.user_id = u.user_id
    WHERE u.user_id = p_user_id;

    -- pixels this user owns (shown on profile canvas)
    SELECT
        px.pixel_id,
        px.challenge_id,
        c.title AS challenge_title,
        px.x_coordinate,
        px.y_coordinate,
        px.color,
        px.last_updated
    FROM pixels AS px
    JOIN challenges AS c ON c.challenge_id = px.challenge_id
    WHERE px.owner_user_id = p_user_id
    ORDER BY px.last_updated DESC;
END$$


-- ============================================
-- 4. GET LEADERBOARD (Statistics page)
--    Returns top 50 users sorted by accepted
--    submissions then owned pixels.
-- ============================================
CREATE PROCEDURE sp_get_leaderboard()
BEGIN
    SELECT
        u.user_id,
        u.username,
        COALESCE(s.accepted_submissions, 0) AS accepted_submissions,
        COALESCE(s.total_submissions, 0)    AS total_submissions,
        COALESCE(p.owned_pixels, 0)         AS owned_pixels
    FROM users AS u
    LEFT JOIN (
        SELECT
            user_id,
            SUM(CASE WHEN result = 'Accepted' THEN 1 ELSE 0 END) AS accepted_submissions,
            COUNT(*)                                              AS total_submissions
        FROM submissions
        GROUP BY user_id
    ) AS s ON s.user_id = u.user_id
    LEFT JOIN (
        SELECT owner_user_id AS user_id, COUNT(*) AS owned_pixels
        FROM pixels
        WHERE owner_user_id IS NOT NULL
        GROUP BY owner_user_id
    ) AS p ON p.user_id = u.user_id
    ORDER BY accepted_submissions DESC, owned_pixels DESC
    LIMIT 50;
END$$


-- ============================================
-- 5. GET CANVAS (PixelCanvas page)
--    Returns all pixels for a challenge so
--    the frontend can render the grid.
-- ============================================
CREATE PROCEDURE sp_get_canvas(IN p_challenge_id INT)
BEGIN
    SELECT
        px.pixel_id,
        px.x_coordinate,
        px.y_coordinate,
        px.color,
        px.owner_user_id,
        u.username AS owner_username,
        px.last_updated
    FROM pixels AS px
    LEFT JOIN users AS u ON u.user_id = px.owner_user_id
    WHERE px.challenge_id = p_challenge_id
    ORDER BY px.x_coordinate, px.y_coordinate;
END$$


-- ============================================
-- 6. GET PIXEL HISTORY (Statistics page)
--    Returns recent ownership changes for
--    the live activity feed on the canvas.
-- ============================================
CREATE PROCEDURE sp_get_pixel_history(IN p_limit INT)
BEGIN
    SET p_limit = COALESCE(p_limit, 20);

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
    JOIN challenges AS c ON c.challenge_id = ph.challenge_id
    LEFT JOIN users AS prev_u ON prev_u.user_id = ph.previous_owner_user_id
    LEFT JOIN users AS new_u  ON new_u.user_id  = ph.new_owner_user_id
    ORDER BY ph.changed_at DESC
    LIMIT p_limit;
END$$

DELIMITER ;
