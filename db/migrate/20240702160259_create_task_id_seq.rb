class CreateTaskIdSeq < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      execute <<-SQL
        CREATE SEQUENCE task_id_seq
        START WITH 1
        INCREMENT BY 1
      SQL
    }
  end

  def down
    safety_assured {
      execute <<-SQL
        DROP SEQUENCE task_id_seq;
      SQL
    }
  end
end
