# frozen_string_literal: true

# AsyncableJobMessaging handles the decision-making around how and whether events in the
# lifecycle of an async job triggers sending a message to the user's inbox.
class AsyncableJobMessaging
  attr_reader :job, :current_user

  def initialize(job:, current_user: nil)
    @job = job
    @current_user = current_user
  end

  def add_job_note(text:, send_to_intake_user:)
    ApplicationRecord.transaction do
      job_note = JobNote.create!(
        job: job,
        user: current_user,
        note: text,
        send_to_intake_user: send_to_intake_user
      )
      if send_to_intake_user && job.asyncable_user
        message_text = <<-EOS.strip_heredoc
          A new note has been added to your #{job.class} job.
          <a href="#{job.path}#job-note-#{job.id}">Click here</a> to view the note.
        EOS
        Message.create!(
          detail: job_note,
          text: message_text,
          user: job.asyncable_user
        )
      end
      job_note
    end
  end
end
