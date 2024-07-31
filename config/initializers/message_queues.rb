# frozen_string_literal: true

# Initializes SQS message queues not for intended for use with
#  asynchronous jobs.
#
# This will primarily be utilized in our development and demo environments.

QUEUE_PREFIX = "caseflow_#{ENV['DEPLOY_ENV']}_"

MESSAGE_QUEUES = [
  {
    name: "receive_notifications.fifo",
    attributes: {
      "FifoQueue" => "true",
      "FifoThroughputLimit" => "perQueue"
    }
  }
].freeze

if Rails.application.config.sqs_create_queues
  sqs_client = Aws::SQS::Client.new
  sqs_client.config[:endpoint] = URI(Rails.application.config.sqs_endpoint)

  MESSAGE_QUEUES.each do |queue_info|
    sqs_client.create_queue({
      queue_name: "#{QUEUE_PREFIX}#{queue_info[:name]}".to_sym,
      attributes: queue_info[:attributes]
    })
  end
end
