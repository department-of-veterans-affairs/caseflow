# frozen_string_literal: true

describe SqsService do
  let(:sqs_client) { SqsService.sqs_client }

  before(:each) { wipe_queues }
  after(:all) { wipe_queues }

  context "#find_queue_url_by_name" do
    let!(:queue) { create_queue(queue_name, fifo) }

    subject { SqsService.find_queue_url_by_name(name: queue_name, check_fifo: false) }

    context "FIFO" do
      let(:fifo) { true }
      let(:queue_name) { "my_fifo_queue" }

      it "the queue is found and is validated to be a FIFO queue" do
        expect(subject { SqsService.find_queue_url_by_name(name: queue_name, check_fifo: true) })
          .to include("caseflow_test_my_fifo_queue.fifo")
      end

      it "the queue is found while validation is opted out" do
        is_expected.to include("caseflow_test_my_fifo_queue.fifo")
      end

      it "a non-existent queue cannot be found" do
        expect { SqsService.find_queue_url_by_name(name: "fake", check_fifo: false) }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::SqsQueueNotFoundError)
          expect(error.to_s).to include("The fake SQS queue is missing in this environment.")
        end
      end
    end

    context "non-FIFO" do
      let(:fifo) { false }
      let(:queue_name) { "my_normal_queue" }

      it "the queue is found" do
        is_expected.to include("caseflow_test_my_normal_queue")
        is_expected.to_not include(".fifo")
      end

      it "the queue found fails the FIFO check" do
        expect { SqsService.find_queue_url_by_name(name: queue_name, check_fifo: true) }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::SqsUnexpectedQueueTypeError)
          expect(error.to_s).to include("No FIFO queue with name my_normal_queue could be located.")
        end
      end
    end
  end

  context "#batch_delete_messages" do
    let!(:queue) { create_queue("batch_delete_test", false) }
    let(:queue_url) { queue.queue_url }

    context "ten or fewer messages are deleted" do
      let!(:initial_messages) { queue_messages(queue_url) }
      let(:received_messages) do
        SqsService.sqs_client.receive_message({
                                                queue_url: queue_url,
                                                max_number_of_messages: 10
                                              }).messages
      end

      it "the messages are deleted properly" do
        expect(approximate_number_of_messages_in_queue(queue_url)).to eq 10

        SqsService.batch_delete_messages(queue_url: queue_url, messages: received_messages)

        expect(approximate_number_of_messages_in_queue(queue_url)).to eq 0
      end
    end

    context "more than ten messages are deleted"
    let!(:initial_messages) { queue_messages(queue_url, 20) }

    let(:received_messages) do
      Array.new(2).flat_map do
        SqsService.sqs_client.receive_message(
          {
            queue_url: queue_url,
            max_number_of_messages: 10
          }
        ).messages
      end
    end

    it "the messages are deleted properly" do
      expect(approximate_number_of_messages_in_queue(queue_url)).to eq 20

      SqsService.batch_delete_messages(queue_url: queue.queue_url, messages: received_messages)

      expect(approximate_number_of_messages_in_queue(queue_url)).to eq 0
    end
  end

  def create_queue(name, fifo = false)
    sqs_client.create_queue({
                              queue_name: "caseflow_test_#{name}#{fifo ? '.fifo' : ''}".to_sym,
                              attributes: fifo ? { "FifoQueue" => "true" } : {}
                            })
  end

  def queue_messages(queue_url, num_to_queue = 10)
    bodies = Array.new(num_to_queue).map.with_index do |_val, idx|
      { test: idx }.to_json
    end

    bodies.each do |body|
      sqs_client.send_message({
                                queue_url: queue_url,
                                message_body: body
                              })
    end
  end

  def approximate_number_of_messages_in_queue(queue_url)
    resp = sqs_client.get_queue_attributes({
                                             queue_url: queue_url,
                                             attribute_names: ["ApproximateNumberOfMessages"]
                                           })

    resp.attributes["ApproximateNumberOfMessages"].to_i
  end

  def wipe_queues
    client = SqsService.sqs_client

    queues_to_delete = client.list_queues.queue_urls.filter { _1.include?("caseflow_test") }

    queues_to_delete.each do |queue_url|
      client.delete_queue(queue_url: queue_url)
    end
  end
end
