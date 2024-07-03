class AssociateTaskIdSeqWithTranscriptions < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      ALTER TABLE transcriptions
      ALTER COLUMN task_id SET DEFAULT nextval('task_id_seq');
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE transcriptions
      ALTER COLUMN task_id DROP DEFAULT;
    SQL
  end
end
