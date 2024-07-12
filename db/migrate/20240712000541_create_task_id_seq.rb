class CreateTaskIdSeq < ActiveRecord::Migration[6.0]
  def up
    safety_assured {
      execute <<-SQL
        CREATE SEQUENCE IF NOT EXISTS task_id_seq
        START WITH 1
        INCREMENT BY 1
      SQL
    }
    if sequence_exists?('task_id_seq')
      puts "Sequence task_id_seq created successfully"
    else
      puts "Failed to create sequence task_id_seq"
    end
  end

  def down
    safety_assured {
      execute <<-SQL
        DROP SEQUENCE IF EXISTS task_id_seq;
      SQL
    }
    unless sequence_exists?('task_id_seq')
      puts "Sequence task_id_seq dropped successfully"
    else
      puts "Failed to drop sequence task_id_seq"
    end
  end

  private

  def sequence_exists?(sequence_name)
    result = ActiveRecord::Base.connection.execute("SELECT * FROM information_schema.sequences WHERE sequence_name = '#{sequence_name}'")
    result.ntuples > 0
  end
end


# schemas = ["pg_toast", "pg_catalog", "public", "information_schema", "caseflow_audit"]

# schemas.each do |schema|
#   result = ActiveRecord::Base.connection.execute("SELECT * FROM information_schema.sequences WHERE sequence_schema = '#{schema}' AND sequence_name = 'task_id_seq'")
#   if result.ntuples > 0
#     puts "Sequence task_id_seq found in schema #{schema}"
#   else
#     puts "Sequence task_id_seq not found in schema #{schema}"
#   end
# end
