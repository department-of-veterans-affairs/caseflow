-- update_transcriptions.sql

-- Up
ALTER TABLE transcriptions
ALTER COLUMN task_id SET DEFAULT nextval('task_id_seq');

-- Down
ALTER TABLE transcriptions
ALTER COLUMN task_id DROP DEFAULT;
