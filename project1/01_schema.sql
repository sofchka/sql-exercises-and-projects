DROP DATABASE IF EXISTS coding_challenge_platform;
CREATE DATABASE coding_challenge_platform;
USE coding_challenge_platform;

-- Separate admin accounts from regular users so challenge management stays isolated from gameplay data.
CREATE TABLE admins (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Users submit solutions, appear on leaderboards, and can own pixels.
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Challenges are the core competitive units and point back to the admin who created them.
CREATE TABLE challenges (
    challenge_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(120) NOT NULL,
    slug VARCHAR(140) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') NOT NULL,
    reward_pixels INT NOT NULL DEFAULT 1,
    created_by_admin_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_challenges_admin FOREIGN KEY (created_by_admin_id) REFERENCES admins(admin_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Test cases belong to one challenge and support automated submission evaluation.
CREATE TABLE test_cases (
    test_case_id INT AUTO_INCREMENT PRIMARY KEY,
    challenge_id INT NOT NULL,
    created_by_admin_id INT NOT NULL,
    input_data TEXT NOT NULL,
    expected_output TEXT NOT NULL,
    is_sample BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_test_cases_challenge FOREIGN KEY (challenge_id) REFERENCES challenges(challenge_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_test_cases_admin FOREIGN KEY (created_by_admin_id) REFERENCES admins(admin_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Execution and memory metrics are stored here so ranking queries can compare performance directly.
CREATE TABLE submissions (
    submission_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    challenge_id INT NOT NULL,
    code TEXT NOT NULL,
    language ENUM('python', 'java', 'cpp', 'javascript', 'sql') NOT NULL,
    result ENUM('Accepted', 'Wrong Answer', 'Time Limit Exceeded', 'Runtime Error') NOT NULL,
    execution_time_ms DECIMAL(8,2) NOT NULL,
    memory_kb INT NOT NULL,
    submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_submissions_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_submissions_challenge FOREIGN KEY (challenge_id) REFERENCES challenges(challenge_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Pixel ownership is optional, which lets accepted submissions claim free pixels later through trigger logic.
CREATE TABLE pixels (
    pixel_id INT AUTO_INCREMENT PRIMARY KEY,
    challenge_id INT NOT NULL,
    x_coordinate INT NOT NULL,
    y_coordinate INT NOT NULL,
    color CHAR(7) NOT NULL,
    owner_user_id INT NULL,
    acquired_submission_id INT NULL,
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_pixels_position UNIQUE (challenge_id, x_coordinate, y_coordinate),
    CONSTRAINT fk_pixels_challenge FOREIGN KEY (challenge_id) REFERENCES challenges(challenge_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pixels_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_pixels_submission FOREIGN KEY (acquired_submission_id) REFERENCES submissions(submission_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_pixels_x CHECK (x_coordinate >= 0),
    CONSTRAINT chk_pixels_y CHECK (y_coordinate >= 0),
    CONSTRAINT chk_pixels_color CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$')
);

-- Pixel history keeps an audit trail for ownership and color transitions.
CREATE TABLE pixel_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    pixel_id INT NOT NULL,
    challenge_id INT NOT NULL,
    previous_owner_user_id INT NULL,
    new_owner_user_id INT NULL,
    changed_by_submission_id INT NULL,
    color_before CHAR(7) NULL,
    color_after CHAR(7) NULL,
    change_type ENUM('ASSIGNED', 'REASSIGNED', 'RELEASED', 'RECOLORED') NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pixel_history_pixel FOREIGN KEY (pixel_id) REFERENCES pixels(pixel_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pixel_history_challenge FOREIGN KEY (challenge_id) REFERENCES challenges(challenge_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pixel_history_previous_owner FOREIGN KEY (previous_owner_user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_pixel_history_new_owner FOREIGN KEY (new_owner_user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_pixel_history_submission FOREIGN KEY (changed_by_submission_id) REFERENCES submissions(submission_id) ON UPDATE CASCADE ON DELETE SET NULL
);

-- The unique constraint prevents duplicate per-test rows for the same submission.
CREATE TABLE submission_test_results (
    submission_test_result_id INT AUTO_INCREMENT PRIMARY KEY,
    submission_id INT NOT NULL,
    test_case_id INT NOT NULL,
    status ENUM('Passed', 'Failed') NOT NULL,
    execution_time_ms DECIMAL(8,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_submission_test_results UNIQUE (submission_id, test_case_id),
    CONSTRAINT fk_submission_test_results_submission FOREIGN KEY (submission_id) REFERENCES submissions(submission_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_submission_test_results_test_case FOREIGN KEY (test_case_id) REFERENCES test_cases(test_case_id) ON UPDATE CASCADE ON DELETE CASCADE
);
