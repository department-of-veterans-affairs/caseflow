# frozen_string_literal: true

# A service class to aid in interacting with Caseflow's SQS queues.
class SqsService
  class << self
    # Intializes an SQS client, or returns a cached version if one has already been initialized.
    #
    # @return [Aws::SQS::Client]
    #  An SQS Client
    def sqs_client
      @sqs_client ||= initialize_sqs_client
    end

    # Locates the URL for a SQS queue based on a provided substring.
    #
    # @param name [String] A substring of the queue's name being searched for.
    # @param check_fifo [Boolean] Whether or not the queue being searched for should be for a FIFO queue.
    #
    # @return [String] The full URL of the SQS queue whose name contains the substring provided.
    def find_queue_url_by_name(name:, check_fifo: false)
      url = sqs_client.list_queues.queue_urls.find { _1.include?(name) && _1.include?(ENV["DEPLOY_ENV"]) }

      fail Caseflow::Error::SqsQueueNotFoundError, "The #{name} SQS queue is missing in this environment." unless url

      # Optional validation check
      if check_fifo && !url.include?(".fifo")
        fail Caseflow::Error::SqsUnexpectedQueueTypeError, "No FIFO queue with name #{name} could be located."
      end

      url
    end

    # Removes the messages provided from a specified queue.
    #
    # @param queue_url [String] The URL of the SQS queue that the messages will be deleted from.
    # @param messages [Array<Aws::SQS::Types::Message>] Messages to be deleted.
    def batch_delete_messages(queue_url:, messages:)
      messages.in_groups_of(10, false).flat_map do |msg_batch|
        sqs_client.delete_message_batch({
                                          queue_url: queue_url,
                                          entries: process_entries_for_batch_delete(msg_batch)
                                        })
      end
    end

    private

    # Intializes an SQS client. Takes into account SQS endpoint overrides and applies them
    # to the instantiated client object.
    #
    # @return [Aws::SQS::Client]
    #  An SQS Client
    def initialize_sqs_client
      sqs_client = Aws::SQS::Client.new

      # Allow for overriding the endpoint requests are sent to via the Rails config.
      if Rails.application.config.sqs_endpoint
        sqs_client.config[:endpoint] = URI(Rails.application.config.sqs_endpoint)
      end

      sqs_client
    end

    # Prepares a batch of messages to be in the format needed for the SQS SDK's delete_message_batch method.
    #
    # @param unprocessed_entries [Array<Aws::SQS::Types::Message>] Messages to be deleted.
    #
    # @return [Array<Hash>] An array where each entry is a hash that contains a unique (per batch)
    # id and a message's receipt handle.
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
