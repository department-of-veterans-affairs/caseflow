# require 'test_helper'
require Rails.root.join('db', 'migrate', '20240712001117_add_task_id_to_transcriptions')

class AddTaskIdToTranscriptionsTest < ActiveSupport::TestCase
  # Setup the migration instance
  def setup
    @migration = AddTaskIdToTranscriptions.new
  end

  # Test the up migration
  test "add task_id column" do
    # Run the up migration
    @migration.up

    # Check that the column exists
    assert_column_exists :transcriptions, :task_id
  end

  # Test the down migration
  test "remove task_id column" do
    # Run the up migration first to ensure the column exists
    @migration.up

    # Then run the down migration
    @migration.down

    # Check that the column no longer exists
    assert_no_column_exists :transcriptions, :task_id
  end
end

# 20220711165637_create_task_id_seq.rb

# class CreateTaskIdSeq < ActiveRecord::Migration[6.0]
#   def up
#     safety_assured {
#       execute <<-SQL
#         CREATE SEQUENCE IF NOT EXISTS task_id_seq
#         START WITH 1
#         INCREMENT BY 1
#       SQL
#     }
#   end

#   def down
#     safety_assured {
#       execute <<-SQL
#         DROP SEQUENCE IF EXISTS task_id_seq;
#       SQL
#     }
#   end
# end

# # 20220711165638_add_task_id_to_transcriptions.rb

# class AddTaskIdToTranscriptions < ActiveRecord::Migration[6.0]
#   def up
#     add_column :transcriptions, :task_id, :bigint
#   end

#   def down
#     remove_column :transcriptions, :task_id
#   end
# end

# # 20220711165639_associate_task_id_seq_with_transcriptions.rb

# class AssociateTaskIdSeqWithTranscriptions < ActiveRecord::Migration[6.0]
#   def up
#     safety_assured {
#     execute <<-SQL
#       ALTER TABLE transcriptions
#       ALTER COLUMN task_id SET DEFAULT nextval('task_id_seq');
#     SQL
#     }
#   end

#   def down
#     safety_assured {
#     execute <<-SQL
#       ALTER TABLE transcriptions
#       ALTER COLUMN task_id DROP DEFAULT;
#     SQL
#     }
#   end
# end

# # db/migrate/20240711170356_create_transcriptions_trigger.rb

# class CreateTranscriptionsTrigger < ActiveRecord::Migration[6.0]
#   def up
#     safety_assured {
#       # SQL to create the trigger function
#       execute <<-SQL
#         CREATE OR REPLACE FUNCTION trg_insert_task_id()
#         RETURNS TRIGGER AS $$
#         BEGIN
#           -- Check if the operation is initiated by a System User
#           IF NEW.created_by_id IS NOT NULL THEN
#             NEW.task_id := nextval('task_id_seq');
#             RETURN NEW;
#           END IF;
#           RETURN NULL; -- Do nothing if not initiated by a System User
#         END;
#         $$ LANGUAGE plpgsql;
#       SQL
#     }

#     safety_assured {
#       # SQL to create the trigger
#       execute <<-SQL
#         CREATE TRIGGER before_insert_transcriptions
#         BEFORE INSERT ON transcriptions
#         FOR EACH ROW
#         EXECUTE FUNCTION trg_insert_task_id();
#       SQL
#     }
#   end

#   def down
#     safety_assured {
#       # SQL to drop the trigger
#       execute "DROP TRIGGER IF EXISTS before_insert_transcriptions ON transcriptions;"
#     }

#     safety_assured {
#       # SQL to drop the trigger function
#       execute "DROP FUNCTION IF EXISTS trg_insert_task_id();"
#     }
#   end
# end

# transcriptions_package.rb code

#  def self.ensure_sequence_exists
#     ActiveRecord::Base.connection.execute(<<-SQL)
#       CREATE SEQUENCE IF NOT EXISTS task_id_seq
#       START WITH 1
#       INCREMENT BY 1;
#     SQL
#   end

