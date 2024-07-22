# frozen_string_literal: true

class SqsService
  class << self
    def sqs_client
      @sqs_client ||= initialize_sqs_client
    end

    def find_queue_url_by_name(name:, check_fifo: false)
      url = sqs_client.list_queues.queue_urls.find { _1.include? name }

      fail Caseflow::Error::SqsQueueNotFoundError, "The #{name} SQS queue is missing in this environment." unless url

      # Optional validation check
      if check_fifo && !url.include?(".fifo")
        fail Caseflow::Error::SqsUnexpectedQueueTypeError, "No FIFO queue with name #{name} could be located."
      end

      url
    end

    def batch_delete_messages(queue_url:, messages:)
      messages.in_groups_of(10, false).flat_map do |msg_batch|
        sqs_client.delete_message_batch({
                                          queue_url: queue_url,
                                          entries: process_entries_for_batch_delete(msg_batch)
                                        })
      end
    end

    private

    def initialize_sqs_client
      sqs_client = Aws::SQS::Client.new

      # Allow for overriding the endpoint requests are sent to via the Rails config.
      if Rails.application.config.sqs_endpoint
        sqs_client.config[:endpoint] = URI(Rails.application.config.sqs_endpoint)
      end

      sqs_client
    end

    def process_entries_for_batch_delete(unprocessed_entries)
      unprocessed_entries.map.with_index do |msg, index|
        {
          id: "message_#{index}",
          receipt_handle: msg.receipt_handle
        }
      end
    end
  end
end
