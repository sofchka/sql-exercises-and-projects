USE coding_challenge_platform;

-- Recursive sequences let the seed script generate large, consistent datasets compactly.
INSERT INTO admins (username, email, password_hash)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 45
)
SELECT
    CONCAT('admin', LPAD(n, 2, '0')),
    CONCAT('admin', LPAD(n, 2, '0'), '@pixelplatform.com'),
    CONCAT('admin_hash_', LPAD(n, 2, '0'))
FROM seq;

-- More than 40 users are inserted to satisfy the project requirement comfortably.
INSERT INTO users (username, email, password_hash)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 50
)
SELECT
    CONCAT('user', LPAD(n, 2, '0')),
    CONCAT('user', LPAD(n, 2, '0'), '@pixelplatform.com'),
    CONCAT('user_hash_', LPAD(n, 2, '0'))
FROM seq;

-- Challenge rows line up with admin IDs so every challenge creator reference is valid.
INSERT INTO challenges (title, slug, description, difficulty, reward_pixels, created_by_admin_id)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 45
)
SELECT
    CONCAT('Challenge ', LPAD(n, 2, '0')),
    CONCAT('challenge-', LPAD(n, 2, '0')),
    CONCAT('Solve coding challenge ', LPAD(n, 2, '0'), ' and compete for leaderboard points and canvas pixels.'),
    ELT(((n - 1) % 3) + 1, 'easy', 'medium', 'hard'),
    ((n - 1) % 5) + 1,
    n
FROM seq;

-- Two test cases per challenge are enough for relationships, views, and procedures without bloating the script.
INSERT INTO test_cases (challenge_id, created_by_admin_id, input_data, expected_output, is_sample)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 90
)
SELECT
    ((n - 1) % 45) + 1,
    ((n - 1) % 45) + 1,
    CONCAT('input_', LPAD(n, 3, '0')),
    CONCAT('output_', LPAD(n, 3, '0')),
    MOD(n, 2) = 1
FROM seq;

-- Pixels start unclaimed so accepted submissions can acquire them through the AFTER INSERT trigger.
INSERT INTO pixels (challenge_id, x_coordinate, y_coordinate, color, owner_user_id, acquired_submission_id)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 90
)
SELECT
    ((n - 1) % 45) + 1,
    FLOOR((n - 1) / 45),
    ((n - 1) % 45) + 1,
    ELT((MOD(n, 6) + 1), '#FF5733', '#33C1FF', '#7DFF33', '#FFC133', '#C733FF', '#FF338A'),
    NULL,
    NULL
FROM seq;

-- Submission times are spaced one minute apart to avoid tripping the anti-spam trigger during seeding.
INSERT INTO submissions (user_id, challenge_id, code, language, result, execution_time_ms, memory_kb, submitted_at)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 120
)
SELECT
    ((n - 1) % 50) + 1,
    ((n - 1) % 45) + 1,
    CONCAT('solution_', LPAD(n, 3, '0')),
    ELT(((n - 1) % 5) + 1, 'python', 'java', 'cpp', 'javascript', 'sql'),
    CASE MOD(n, 4)
        WHEN 0 THEN 'Accepted'
        WHEN 1 THEN 'Accepted'
        WHEN 2 THEN 'Wrong Answer'
        ELSE 'Time Limit Exceeded'
    END,
    40 + (n * 1.75),
    256 + (n * 8),
    TIMESTAMPADD(MINUTE, n, '2026-01-01 09:00:00')
FROM seq;

-- Test-result rows are derived from submissions so the pass/fail state stays consistent with the submission result.
INSERT INTO submission_test_results (submission_id, test_case_id, status, execution_time_ms)
SELECT
    s.submission_id,
    ((s.challenge_id - 1) * 2) + CASE WHEN MOD(s.submission_id, 2) = 0 THEN 1 ELSE 2 END,
    CASE WHEN s.result = 'Accepted' THEN 'Passed' ELSE 'Failed' END,
    ROUND(s.execution_time_ms * 0.95, 2)
FROM submissions AS s;
