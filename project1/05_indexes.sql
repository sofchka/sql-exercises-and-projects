USE coding_challenge_platform;

-- These indexes support the join and filter patterns used most often by queries, views, triggers, and procedures.
CREATE INDEX idx_submissions_user_id ON submissions(user_id);
CREATE INDEX idx_submissions_challenge_id ON submissions(challenge_id);
CREATE INDEX idx_submissions_result_time ON submissions(result, execution_time_ms);
CREATE INDEX idx_test_cases_challenge_id ON test_cases(challenge_id);
CREATE INDEX idx_pixels_owner_user_id ON pixels(owner_user_id);
CREATE INDEX idx_pixels_challenge_owner ON pixels(challenge_id, owner_user_id);
CREATE INDEX idx_pixel_history_pixel_id ON pixel_history(pixel_id);
CREATE INDEX idx_pixel_history_new_owner ON pixel_history(new_owner_user_id);
CREATE INDEX idx_submission_test_results_submission_id ON submission_test_results(submission_id);
CREATE INDEX idx_submission_test_results_test_case_id ON submission_test_results(test_case_id);
