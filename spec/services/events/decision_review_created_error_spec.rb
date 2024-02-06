# frozen_string_literal: true

describe Events::DecisionReviewCreatedError do
  let!(:consumer_event_id) { "999" }
  let!(:errored_claim_id) { "8888" }
  let!(:error_message) { "The DecisionReviewCreation had an error" }
  describe "#handle_service_error" do
    subject { described_class.handle_service_error(consumer_event_id, errored_claim_id, error_message) }

    context "When Decision Review Creation Error is Saved in Caseflow" do
      it "should create a new event with an updated Error" do
        subject
        new_event = Event.find_by(reference_id: "999")
        expect(new_event.reference_id).to eq(consumer_event_id)
        expect(new_event.error).to eq(error_message)
        expect(new_event.info).to eq("errored_claim_id" => "8888")
        expect(new_event.errored_claim_id).to eq(errored_claim_id)
      end
    end
    context "when lock acquisition fails" do
      before do
        allow(RedisMutex).to receive(:with_lock).and_raise(RedisMutex::LockError)
      end

      it "logs the error message" do
        expect(Rails.logger).to receive(:error)
          .with("Failed to acquire lock for Claim ID: #{errored_claim_id}! This Event is being"\
                " processed. Please try again later.")
        subject
      end
    end
    context "when standard error is raised" do
      it "logs an error and raises if an standard error occurs" do
        allow_any_instance_of(Event).to receive(:update!).and_raise(StandardError)
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
