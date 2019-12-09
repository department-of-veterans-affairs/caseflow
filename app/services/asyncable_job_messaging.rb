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
      job_note = JobNote.create!(job: job, user: current_user, note: text, send_to_intake_user: send_to_intake_user)
      if send_to_intake_user && job.asyncable_user
        message_text = <<-EOS.strip_heredoc
          A new note has been added to your #{job.class} job.
          <a href="#{job_note.path}">Click here</a> to view the note.
        EOS
        Message.create!(detail: job_note, text: message_text, user: job.asyncable_user, message_type: :job_note_added)
      end
      job_note
    end
  end

  def add_job_cancellation_note(text:)
    send_to_intake_user = !!job.asyncable_user
    ApplicationRecord.transaction do
      text = "This job has been cancelled with the following note:\n#{text}"
      job_note = JobNote.create!(job: job, user: current_user, note: text, send_to_intake_user: send_to_intake_user)
      if send_to_intake_user
        message_text = <<-EOS.strip_heredoc
          The job for processing <a href="#{job_note.path}">#{job.class} #{job.id}</a> has been cancelled.
        EOS
        Message.create!(detail: job_note, text: message_text, user: job.asyncable_user, message_type: :job_cancelled)
      end
      job_note
    end
  end

  def handle_job_failure
    return unless messaging_enabled_for_job_attempt?
    return if job.messages.job_failing.any?

    err = ERB::Util.html_escape(job.sanitized_error)
    message_text = <<-EOS.strip_heredoc
      The job for <a href="#{job.path}">#{job.class} #{job.id}</a> was unable to complete because of an error: #{err}
    EOS
    Message.create!(
      detail: job,
      text: message_text,
      user: job.asyncable_user,
      message_type: :job_failing
    )
  end

  def handle_job_success
    return unless messaging_enabled_for_job_attempt?
    return if job.messages.failing_job_succeeded.any?

    message_text = <<-EOS.strip_heredoc
      <a href="#{job.path}">#{job.class} #{job.id}</a> has successfully been processed.
      No further action is necessary. If you have opened a support ticket for this issue,
      you may inform them that it may be closed.
    EOS
    Message.create!(
      detail: job,
      text: message_text,
      user: job.asyncable_user,
      message_type: "failing_job_succeeded"
    )
  end

  private

  def messaging_enabled_for_job_attempt?
    return false unless job.submitted? && job.asyncable_user

    Time.zone.now - job[job.class.submitted_at_column] >= FAILING_TIME_BEFORE_MESSAGING
  end
end
