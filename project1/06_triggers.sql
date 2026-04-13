USE coding_challenge_platform;

DROP TRIGGER IF EXISTS trg_submissions_before_insert;
DROP TRIGGER IF EXISTS trg_submissions_after_insert;
DROP TRIGGER IF EXISTS trg_pixels_after_update;
DROP TRIGGER IF EXISTS trg_submission_test_results_before_insert;

DELIMITER $$

-- Normalize missing metrics and reject submissions that arrive too quickly for the same challenge.
CREATE TRIGGER trg_submissions_before_insert
BEFORE INSERT ON submissions
FOR EACH ROW
BEGIN
    DECLARE v_last_submission_time DATETIME;

    IF NEW.execution_time_ms IS NULL OR NEW.execution_time_ms <= 0 THEN
        SET NEW.execution_time_ms = 1.00;
    END IF;

    IF NEW.memory_kb IS NULL OR NEW.memory_kb <= 0 THEN
        SET NEW.memory_kb = 256;
    END IF;

    IF NEW.submitted_at IS NULL THEN
        SET NEW.submitted_at = CURRENT_TIMESTAMP;
    END IF;

    SELECT MAX(submitted_at)
    INTO v_last_submission_time
    FROM submissions
    WHERE user_id = NEW.user_id
      AND challenge_id = NEW.challenge_id;

    IF v_last_submission_time IS NOT NULL AND TIMESTAMPDIFF(SECOND, v_last_submission_time, NEW.submitted_at) < 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Submission must be at least 5 seconds after the previous submission for the same challenge.';
    END IF;
END$$

-- Accepted submissions claim the first available pixel for that challenge.
CREATE TRIGGER trg_submissions_after_insert
AFTER INSERT ON submissions
FOR EACH ROW
BEGIN
    DECLARE v_pixel_id INT DEFAULT NULL;

    IF NEW.result = 'Accepted' THEN
        SELECT pixel_id
        INTO v_pixel_id
        FROM pixels
        WHERE challenge_id = NEW.challenge_id
          AND owner_user_id IS NULL
        ORDER BY x_coordinate, y_coordinate, pixel_id
        LIMIT 1;

        IF v_pixel_id IS NOT NULL THEN
            UPDATE pixels
            SET owner_user_id = NEW.user_id,
                acquired_submission_id = NEW.submission_id,
                last_updated = NEW.submitted_at
            WHERE pixel_id = v_pixel_id;
        END IF;
    END IF;
END$$

-- NULL-safe comparison (<=>) is required so ownership changes involving NULL are not missed.
CREATE TRIGGER trg_pixels_after_update
AFTER UPDATE ON pixels
FOR EACH ROW
BEGIN
    IF NOT (OLD.owner_user_id <=> NEW.owner_user_id) OR NOT (OLD.color <=> NEW.color) THEN
        INSERT INTO pixel_history (
            pixel_id,
            challenge_id,
            previous_owner_user_id,
            new_owner_user_id,
            changed_by_submission_id,
            color_before,
            color_after,
            change_type,
            changed_at
        )
        VALUES (
            NEW.pixel_id,
            NEW.challenge_id,
            OLD.owner_user_id,
            NEW.owner_user_id,
            NEW.acquired_submission_id,
            OLD.color,
            NEW.color,
            CASE
                WHEN OLD.owner_user_id IS NULL AND NEW.owner_user_id IS NOT NULL THEN 'ASSIGNED'
                WHEN OLD.owner_user_id IS NOT NULL AND NEW.owner_user_id IS NULL THEN 'RELEASED'
                WHEN NOT (OLD.owner_user_id <=> NEW.owner_user_id) THEN 'REASSIGNED'
                ELSE 'RECOLORED'
            END,
            CURRENT_TIMESTAMP
        );
    END IF;
END$$

-- If a per-test runtime is omitted, inherit a sensible value from the parent submission.
CREATE TRIGGER trg_submission_test_results_before_insert
BEFORE INSERT ON submission_test_results
FOR EACH ROW
BEGIN
    IF NEW.execution_time_ms IS NULL OR NEW.execution_time_ms <= 0 THEN
        SET NEW.execution_time_ms = COALESCE(
            (SELECT execution_time_ms FROM submissions WHERE submission_id = NEW.submission_id),
            1.00
        );
    END IF;
END$$

DELIMITER ;
