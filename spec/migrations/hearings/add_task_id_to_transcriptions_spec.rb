# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db", "migrate", "20240712142557_add_task_id_to_transcriptions")

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
