# frozen_string_literal: true

# Deletes the message from the associated SQS queue if the job class
# specifies that this operation should take place PRIOR to the job being initiated.
#
# This will occur if the job will take longer than the SQS queue's visibility timeout
# which would potentially allow multiple instances of the same job to be executed.
class JobMessageDeletionMiddleware
  # :reek:LongParameterList
  def call(_worker, _queue, msg, body)
    if body["job_class"].constantize::DELETE_SQS_MESSAGE_BEFORE_START
      msg.client.delete_message(queue_url: msg.queue_url, receipt_handle: msg.data.receipt_handle)
    end

    yield
  end
end
