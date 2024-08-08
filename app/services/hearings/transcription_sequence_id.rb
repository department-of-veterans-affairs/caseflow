# frozen_string_literal: true

# This file defines a Ruby function that mimics the functionality of the PL/SQL trigger.
# It's not a direct translation, but provides a similar behavior for managing task IDs.

# Define a constant to represent the system generated tag.
SYSTEM_GEN_TAG = User.system_user.id

# Define a class to represent the transcriptions table.
class Hearings::TranscriptionSequenceId
  attr_accessor :created_by_id, :task_id

  # Initialize a new transcription object.
  def initialize(created_by_id, task_id)
    # rubocop:disable Style/ClassVars
    @@created_by_id = created_by_id
    @@task_id = task_id
    # rubocop:enable Style/ClassVars
  end
end

# Define a function to simulate the trigger behavior.
def trg_myseq(transcription)
  # Check if the transcription was created by the system.
  if transcription.created_by_id == SYSTEM_GEN_TAG
    # Generate a new task ID if the transcription was created by the system.
    transcription.task_id = next_task_id
  end
  # Return the updated transcription object.
  transcription
end

# Define a function to simulate the sequence.
def next_task_id
  # Replace this with your actual sequence implementation.
  # For example, you could use a database or a counter variable.
  # This implementation simply returns an incremented value.
  @next_task_id ||= 0
  @next_task_id += 1
end

# Simulate the trigger execution.
def before_insert_on_transcriptions(transcription)
  # Call the trigger function to update the task ID.
  trg_myseq(transcription)
end
