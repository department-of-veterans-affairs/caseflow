# frozen_string_literal: true

class JobSentryScopeMiddleware
  # :nocov:
  def call(_worker, queue, sqs_msg, body)
    # The structure for the `body` is described here:
    #
    #   https://github.com/phstc/shoryuken/wiki/Sending-a-message
    job_class = body["job_class"].constantize
    msg_id = sqs_msg.message_id
    job_start_time = Time.zone.now
    job_info = AwsJobLogHelper::JobInfo.new(
      job_class,
      msg_id,
      start_time: job_start_time,
      end_time: job_start_time + 1.day # Assume the job will complete in a day
    )
    application = job_class.try(:app_name)

    tags = {
      application: application,
      job: job_class.name,
      queue: queue
    }
    # Note: job class and job id are already sent to Sentry by default.
    context = {
      application: application,
      aws_log_url: job_info.url,
      msg_id: msg_id,
      start_time: job_start_time
    }

    Raven.tags_context(tags)
    Raven.extra_context(context)
    yield
  end
  # :nocov:
end
