USE coding_challenge_platform;

SELECT user_id, username, email, created_at
FROM users
ORDER BY user_id;

SELECT challenge_id, title, difficulty, reward_pixels
FROM challenges
ORDER BY challenge_id;

SELECT s.submission_id, u.username, c.title, s.language, s.result, s.execution_time_ms, s.submitted_at
FROM submissions AS s
JOIN users AS u ON u.user_id = s.user_id
JOIN challenges AS c ON c.challenge_id = s.challenge_id
ORDER BY s.submission_id;

SELECT c.challenge_id, c.title, COUNT(*) AS accepted_submissions
FROM submissions AS s
JOIN challenges AS c ON c.challenge_id = s.challenge_id
WHERE s.result = 'Accepted'
GROUP BY c.challenge_id, c.title
ORDER BY accepted_submissions DESC, c.challenge_id;

SELECT u.user_id, u.username, COUNT(*) AS total_submissions
FROM submissions AS s
JOIN users AS u ON u.user_id = s.user_id
GROUP BY u.user_id, u.username
ORDER BY total_submissions DESC, u.user_id;

SELECT u.user_id, u.username, COUNT(*) AS owned_pixels
FROM pixels AS p
JOIN users AS u ON u.user_id = p.owner_user_id
GROUP BY u.user_id, u.username
ORDER BY owned_pixels DESC, u.user_id;

SELECT ph.history_id, ph.pixel_id, ph.previous_owner_user_id, ph.new_owner_user_id, ph.change_type, ph.changed_at
FROM pixel_history AS ph
ORDER BY ph.changed_at DESC, ph.history_id DESC;

SELECT s.submission_id, str.status, str.execution_time_ms, str.test_case_id
FROM submission_test_results AS str
JOIN submissions AS s ON s.submission_id = str.submission_id
ORDER BY s.submission_id, str.test_case_id;

SELECT c.challenge_id, c.title, MIN(s.execution_time_ms) AS fastest_execution_time_ms
FROM submissions AS s
JOIN challenges AS c ON c.challenge_id = s.challenge_id
WHERE s.result = 'Accepted'
GROUP BY c.challenge_id, c.title
ORDER BY fastest_execution_time_ms, c.challenge_id;

SELECT u.user_id, u.username
FROM users AS u
LEFT JOIN submissions AS s ON s.user_id = u.user_id
WHERE s.submission_id IS NULL
ORDER BY u.user_id;
