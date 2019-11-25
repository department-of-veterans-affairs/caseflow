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
    it "sets extra context" do
      allow(Raven).to receive(:extra_context)
      JobThatIsGood.perform_now
      expect(Raven).to have_received(:extra_context).with(application: "fake")
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
