# frozen_string_literal: true

class JobSentryScopeMiddleware
  # :nocov:
  def call(_worker, _queue, sqs_msg, body)
    # The structure for the `body` is described here:
    #
    #   https://github.com/phstc/shoryuken/wiki/Sending-a-message
    job_class = body["job_class"].constantize
    job_id = body["job_id"]
    msg_id = sqs_msg.message_id
    job_start_time = Time.zone.now
    #job_info = AwsJobLogHelper::JobInfo(
    #  job_class,
    #  msg_id,
    #  start_time: job_start_time,
    #  end_time: job_start_time + 1.day # Assume the job will complete in a day
    #)

    tags = {
      application: job_class.try(:app_name)
    }
    # Note: job class and job id are already sent to Sentry by default.
    context = {
      #aws_log_url: job_info.url,
      msg_id: msg_id,
      start_time: job_start_time
    }

    Raven.tags_context(tags) do
      Raven.extra_context(context) { yield }
    end
  end
  # :nocov:
end
