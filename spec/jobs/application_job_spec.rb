# frozen_string_literal: true

class JobThatIsGood < ApplicationJob
  queue_with_priority :high_priority
  application_attr :fake

  def perform(target = nil)
    target&.do_something("hello")
  end
end

describe "ApplicationJob" do
  context ".application_attr" do
    it "sets application request store" do
      JobThatIsGood.perform_now
      expect(RequestStore[:application]).to eq("fake_job")
    end

    it "sets extra context in middleware" do
      allow(Raven).to receive(:extra_context)

      sqs_msg = double("sqs_msg")
      allow(sqs_msg).to receive(:message_id).and_return("msgid")

      JobSentryScopeMiddleware.new.call(
        double("worker"),
        "high_priority",
        sqs_msg,
        ActiveSupport::HashWithIndifferentAccess.new(job_class: "JobThatIsGood", job_id: "jobid")
      ) {}

      expect(Raven).to have_received(:extra_context).with(hash_including(application: :fake))
    end
  end

  context ".queue_with_priority" do
    it "performs with valid priority" do
      target = double("target")
      allow(target).to receive(:do_something)

      JobThatIsGood.perform_now target

      expect(target).to have_received(:do_something).with("hello").once
    end

    it "fails with invalid priority" do
      expect do
        class JobWithInvalidPriority < JobThatIsGood
          queue_with_priority :high
        end
      end.to raise_error(ApplicationJob::InvalidJobPriority, "high is not a valid job priority!")
    end
  end
end
