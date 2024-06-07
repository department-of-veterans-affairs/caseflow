# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, type: :model do
  let!(:consumer_event_id) { "123" }
  let(:event_created) { DecisionReviewCreatedEvent.create!(reference_id: consumer_event_id, completed_at: nil) }
  let!(:completed_event) { DecisionReviewCreatedEvent.create!(reference_id: "999", completed_at: Time.zone.now) }

  describe "attributes" do
    it { expect(described_class.new.info).to be_an_instance_of(Hash) }

    it "allows nil value for errored_claim_id" do
      event = described_class.new(errored_claim_id: nil)
      expect(event.errored_claim_id).to be_nil
    end
  end

  describe "scopes" do
    describe ".with_errored_claim_id" do
      it "includes events with non-null errored_claim_id" do
        event_with_errored_claim = create(:decision_review_created_event, info: { "errored_claim_id" => "12345" })
        event_without_errored_claim = create(:decision_review_created_event, info: { "created" => "Yay!" })

        events = described_class.with_errored_claim_id

        expect(events).to include(event_with_errored_claim)
        expect(events).not_to include(event_without_errored_claim)
      end
    end
  end

  describe "#exists_and_is_completed?" do
    context "When there is no previous Event" do
      it "should return false" do
        expect(described_class.exists_and_is_completed?(consumer_event_id)).to be_falsey
      end
    end

    context "Where there is a previous Event that was completed" do
      it "should return true" do
        expect(described_class.exists_and_is_completed?("999")).to be_truthy
      end
    end
  end
end
