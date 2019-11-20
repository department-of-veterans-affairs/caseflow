# frozen_string_literal: true

# AsyncableJobMessaging handles the decision-making around how and whether events in the
# lifecycle of an async job triggers sending a message to the user's inbox.
class AsyncableJobMessaging
  FAILING_TIME_BEFORE_MESSAGING = 1.day.freeze

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
          user: job.asyncable_user,
          message_type: "job_note_added"
        )
      end
      job_note
    end
  end

  def handle_job_failure(err:)
    return unless job.asyncable_user
    return unless job.submitted?
    return unless Time.zone.now - job[job.class.submitted_at_column] >= FAILING_TIME_BEFORE_MESSAGING
    return if Message.where(detail: job, message_type: "job_failing").any?

    if err.length > 80
      err = err[0..80] + "..."
    end
    message_text = <<-EOS.strip_heredoc
      The Intake processing job for <a href="#{job.path}">#{job.class} #{job.id}</a> was unable to complete because of an error: #{err}
    EOS
    Message.create!(
      detail: job,
      text: message_text,
      user: job.asyncable_user,
      message_type: "job_failing"
    )
  end
end
