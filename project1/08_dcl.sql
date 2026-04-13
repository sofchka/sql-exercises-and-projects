USE coding_challenge_platform;

DROP USER IF EXISTS 'app_user'@'localhost';
DROP USER IF EXISTS 'admin_user'@'localhost';

CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'AppUser#2026';
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'AdminUser#2026';

GRANT SELECT, INSERT, UPDATE, EXECUTE ON coding_challenge_platform.* TO 'app_user'@'localhost';
GRANT ALL PRIVILEGES ON coding_challenge_platform.* TO 'admin_user'@'localhost';

FLUSH PRIVILEGES;
