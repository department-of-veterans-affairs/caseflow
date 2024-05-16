# frozen_string_literal: true

module MessageConfigurations::DeleteMessageBeforeStart
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Include this module in job classes if you anticipate that the job will take longer than the SQS visibility
    # timeout value (ex: currently 5 hours for our low priority queue at the time of writing this)
    # to prevent multiple instances of the job from being executed.
    #
    # See https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html
    def delete_sqs_message_before_start?
      true
    end
  end
end
