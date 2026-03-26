-- USERS table
CREATE TABLE USERS (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL
);

-- LEADERBOARD table
CREATE TABLE LEADERBOARD (
    leaderboard_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    score INT NOT NULL,
    rank INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES USERS(user_id)
);

-- CHALLENGES table
CREATE TABLE CHALLENGES (
    challenge_id INT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    difficulty INT NOT NULL,
    created_at DATETIME NOT NULL,
    creator_id INT NOT NULL,
    FOREIGN KEY (creator_id) REFERENCES USERS(user_id)
);

-- PIXELS table
CREATE TABLE PIXELS (
    pixel_id INT PRIMARY KEY,
    x_coordinate INT NOT NULL,
    y_coordinate INT NOT NULL,
    owner_id INT NOT NULL,
    challenge_id INT NOT NULL,
    color_last_updated DATETIME NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES USERS(user_id),
    FOREIGN KEY (challenge_id) REFERENCES CHALLENGES(challenge_id)
);

-- SUBMISSIONS table
CREATE TABLE SUBMISSIONS (
    submission_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    challenge_id INT NOT NULL,
    code TEXT NOT NULL,
    submitted_at DATETIME NOT NULL,
    execution_time FLOAT NOT NULL,
    result VARCHAR(20) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES USERS(user_id),
    FOREIGN KEY (challenge_id) REFERENCES CHALLENGES(challenge_id)
);

-- TESTCASES table
CREATE TABLE TESTCASES (
    test_id INT PRIMARY KEY,
    challenge_id INT NOT NULL,
    input TEXT NOT NULL,
    expected_output TEXT NOT NULL,
    FOREIGN KEY (challenge_id) REFERENCES CHALLENGES(challenge_id)
);

-- PIXELHISTORY table
CREATE TABLE PIXELHISTORY (
    history_id INT PRIMARY KEY,
    pixel_id INT NOT NULL,
    new_owner_id INT NOT NULL,
    previous_owner_id INT NOT NULL,
    changed_at DATETIME NOT NULL,
    FOREIGN KEY (pixel_id) REFERENCES PIXELS(pixel_id),
    FOREIGN KEY (new_owner_id) REFERENCES USERS(user_id),
    FOREIGN KEY (previous_owner_id) REFERENCES USERS(user_id)
);
