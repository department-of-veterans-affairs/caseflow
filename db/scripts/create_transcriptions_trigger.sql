-- db/scripts/create_transcriptions_trigger.sql

CREATE OR REPLACE FUNCTION trg_insert_task_id()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the operation is initiated by a System User
  IF NEW.created_by_id IS NOT NULL THEN
    NEW.task_id := nextval('task_id_seq');
    RETURN NEW;
  END IF;
  RETURN NULL; -- Do nothing if not initiated by a System User
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_transcriptions
BEFORE INSERT ON transcriptions
FOR EACH ROW
EXECUTE FUNCTION trg_insert_task_id();
