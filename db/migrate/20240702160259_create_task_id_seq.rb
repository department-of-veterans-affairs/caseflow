class CreateTaskIdSeq < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      CREATE SEQUENCE task_id_seq
      START WITH 1
      INCREMENT BY 1
      NOCACHE;
    SQL
  end

  def down
    execute <<-SQL
      DROP SEQUENCE task_id_seq;
    SQL
  end
end
