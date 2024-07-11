class CreateTranscriptionsTrigger < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      # SQL to create the trigger function
      execute <<-SQL
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
      SQL
    }

    safety_assured {
      # SQL to create the trigger
      execute <<-SQL
        CREATE TRIGGER before_insert_transcriptions
        BEFORE INSERT ON transcriptions
        FOR EACH ROW
        EXECUTE FUNCTION trg_insert_task_id();
      SQL
    }
  end

  def down
    safety_assured {
      # SQL to drop the trigger
      execute "DROP TRIGGER IF EXISTS before_insert_transcriptions ON transcriptions;"
    }

    safety_assured {
      # SQL to drop the trigger function
      execute "DROP FUNCTION IF EXISTS trg_insert_task_id();"
    }
  end
end
