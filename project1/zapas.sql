-- ============================================
-- DQL (Data Query Language)
-- Used to RETRIEVE data from the database
-- ============================================


-- ============================================
-- 1. BASIC SELECT (retrieve all users)
-- ============================================

-- SELECT * means "select all columns"
SELECT * 
FROM USERS;


-- ============================================
-- 2. SELECT SPECIFIC COLUMNS
-- ============================================

-- only get usernames and emails (not all columns)
SELECT username, email
FROM USERS;


-- ============================================
-- 3. FILTERING DATA (WHERE)
-- ============================================

-- get only accepted submissions
SELECT *
FROM SUBMISSIONS
WHERE result = 'Accepted';  -- condition


-- ============================================
-- 4. MULTIPLE CONDITIONS (AND)
-- ============================================

-- accepted submissions with execution time < 1 second
SELECT *
FROM SUBMISSIONS
WHERE result = 'Accepted'
AND execution_time < 1;


-- ============================================
-- 5. SORTING RESULTS (ORDER BY)
-- ============================================

-- order submissions by execution time (fastest first)
SELECT *
FROM SUBMISSIONS
ORDER BY execution_time ASC; -- ASC = ascending, DESC = descending


-- ============================================
-- 6. LIMIT RESULTS
-- ============================================

-- get top 5 fastest submissions
SELECT *
FROM SUBMISSIONS
ORDER BY execution_time ASC
LIMIT 5;


-- ============================================
-- 7. JOIN (VERY IMPORTANT)
-- Combine data from multiple tables
-- ============================================

-- show submissions with usernames
SELECT u.username, s.submission_id, s.result
FROM SUBMISSIONS s
JOIN USERS u ON s.user_id = u.user_id;

-- explanation:
-- s and u are aliases (short names)
-- JOIN connects tables using matching keys


-- ============================================
-- 8. JOIN WITH MULTIPLE TABLES
-- ============================================

-- show submission + challenge title + user
SELECT u.username, c.title, s.result
FROM SUBMISSIONS s
JOIN USERS u ON s.user_id = u.user_id
JOIN CHALLENGES c ON s.challenge_id = c.challenge_id;


-- ============================================
-- 9. LEFT JOIN (include NULL values)
-- ============================================

-- show all pixels (even if no owner)
SELECT p.pixel_id, u.username
FROM PIXELS p
LEFT JOIN USERS u ON p.user_id = u.user_id;

-- LEFT JOIN = keep all rows from left table (PIXELS)


-- ============================================
-- 10. COUNT (aggregation)
-- ============================================

-- count total users
SELECT COUNT(*) AS total_users
FROM USERS;


-- ============================================
-- 11. GROUP BY (aggregation per user)
-- ============================================

-- number of submissions per user
SELECT user_id, COUNT(*) AS total_submissions
FROM SUBMISSIONS
GROUP BY user_id;


-- ============================================
-- 12. LEADERBOARD (IMPORTANT QUERY)
-- ============================================

-- count accepted submissions per user
SELECT user_id, COUNT(*) AS score
FROM SUBMISSIONS
WHERE result = 'Accepted'
GROUP BY user_id
ORDER BY score DESC;

-- ORDER BY score DESC = highest score first


-- ============================================
-- 13. HAVING (filter after GROUP BY)
-- ============================================

-- users with more than 3 accepted submissions
SELECT user_id, COUNT(*) AS score
FROM SUBMISSIONS
WHERE result = 'Accepted'
GROUP BY user_id
HAVING COUNT(*) > 3;


-- ============================================
-- 14. SUBQUERY (query inside query)
-- ============================================

-- users who have submitted at least once
SELECT username
FROM USERS
WHERE user_id IN (
    SELECT user_id FROM SUBMISSIONS
);

-- IN = check if value exists in another query


-- ============================================
-- 15. USERS WITH NO SUBMISSIONS (IMPORTANT)
-- ============================================

SELECT username
FROM USERS
WHERE user_id NOT IN (
    SELECT user_id FROM SUBMISSIONS
);


-- ============================================
-- 16. PIXELS OWNED BY USERS
-- ============================================

SELECT u.username, p.x_coordinate, p.y_coordinate
FROM PIXELS p
JOIN USERS u ON p.user_id = u.user_id;


-- ============================================
-- 17. PIXEL HISTORY (ownership changes)
-- ============================================

SELECT pixel_id, previous_owner_id, new_owner_id, changed_at
FROM PIXELHISTORY
ORDER BY changed_at DESC;


-- ============================================
-- 18. TEST CASE RESULTS FOR SUBMISSIONS
-- ============================================

SELECT submission_id, status, execution_time
FROM SUBMISSIONTESTRESULTS;


-- ============================================
-- 19. COMPLEX QUERY (REAL SYSTEM VIEW)
-- ============================================

-- show full submission info (user + challenge + result)
SELECT 
    u.username,
    c.title,
    s.result,
    s.execution_time
FROM SUBMISSIONS s
JOIN USERS u ON s.user_id = u.user_id
JOIN CHALLENGES c ON s.challenge_id = c.challenge_id;


-- ============================================
-- 20. FASTEST SOLUTION PER CHALLENGE
-- ============================================

SELECT challenge_id, MIN(execution_time) AS fastest_time
FROM SUBMISSIONS
GROUP BY challenge_id;


-- ============================================
-- END OF DQL FILE
-- ============================================
