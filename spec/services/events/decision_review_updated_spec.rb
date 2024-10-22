# frozen_string_literal: true

describe Events::DecisionReviewUpdated do
  let(:consumer_event_id) { "1234567890" }
  let(:claim_id) { "12201" }
  let(:event) { DecisionReviewUpdatedEvent.new(reference_id: consumer_event_id) }
  let(:parser) do
    double(
      "Parser",
      css_id: "css_id",
      station_id: "station_id",
      end_product_establishment_reference_id: "ep_ref_id"
    )
  end
  let(:review) { double("Review", reference_id: "1234567890") }
  let(:params) { { consumer_event_id: consumer_event_id, claim_id: claim_id } }
  let(:headers) { {} }
  let(:payload) { {} }
  let(:user) { double("User") }
  let(:end_product_establishment) do
    double("EndProductEstablishment", source: review)
  end
  subject { described_class.update!(params, headers, payload) }

  before do
    allow(DecisionReviewUpdatedEvent).to receive(:find_or_create_by)
      .with(reference_id: consumer_event_id).and_return(event)
    allow(Events::DecisionReviewUpdated::DecisionReviewUpdatedParser).to receive(:new)
      .with(headers, payload).and_return(parser)
    allow(Events::CreateUserOnEvent).to receive(:handle_user_creation_on_event)
      .with(event: event, css_id: parser.css_id, station_id: parser.station_id).and_return(user)
    allow(EndProductEstablishment).to receive(:find_by)
      .with(reference_id: parser.end_product_establishment_reference_id).and_return(end_product_establishment)
    # allow(Events::DecisionReviewUpdated::UpdateInformalConference).to receive(:process!)
    #   .with(event: event, parser: parser).and_return(nil)
    allow(Events::DecisionReviewUpdated::UpdateClaimReview).to receive(:process!)
      .with(event: event, parser: parser).and_return(nil)
    allow(Events::DecisionReviewUpdated::UpdateEndProductEstablishment).to receive(:process!)
      .with(event: event, parser: parser).and_return(nil)
    allow(RequestIssuesUpdateEvent).to receive(:new)
      .with(user: user, review: review, parser: parser, event: event, epe: end_product_establishment)
      .and_return(double("RequestIssuesUpdateEvent", perform!: nil))
  end

  describe ".update!" do
    subject { described_class.update!(params, headers, payload) }

    context "when lock acquisition fails" do
      it_behaves_like "when lock acquisition fails", "12201"
    end

    context "when lock Key is already in the Redis Cache" do
      it_behaves_like "when lock key is already in the Redis Cache", "12201"
    end

    it "finds or creates an event" do
      expect(DecisionReviewUpdatedEvent).to receive(:find_or_create_by).with(reference_id: consumer_event_id)
      subject
    end

    it "creates a user" do
      expect(Events::CreateUserOnEvent).to receive(:handle_user_creation_on_event)
        .with(event: event, css_id: parser.css_id, station_id: parser.station_id)
      subject
    end

    it "finds an end product establishment" do
      expect(EndProductEstablishment).to receive(:find_by)
        .with(reference_id: parser.end_product_establishment_reference_id)
      subject
    end

    it "updates claim review" do
      expect(Events::DecisionReviewUpdated::UpdateClaimReview).to receive(:process!).with(event: event, parser: parser)
      subject
    end

    it "updates end product establishment" do
      expect(Events::DecisionReviewUpdated::UpdateEndProductEstablishment).to receive(:process!)
        .with(event: event, parser: parser)
      subject
    end

    it "updates request issues" do
      expect(RequestIssuesUpdateEvent).to receive(:new)
        .with(user: user, review: review, parser: parser, event: event, epe: end_product_establishment)
        .and_return(double("RequestIssuesUpdateEvent", perform!: nil))
      subject
    end

    it "updates the event" do
      expect(event).to receive(:update!)
      subject
    end
  end

  context "when a StandardError occurs" do
    let(:standard_error) { StandardError.new("Lions, tigers, and bears, OH MY!") }

    before do
      allow(RequestIssuesUpdateEvent).to receive(:new)
        .with(user: user, review: review, parser: parser, event: event, epe: end_product_establishment)
        .and_raise(standard_error)
      allow(Rails.logger).to receive(:error)
    end

    it "the error is logged" do
      expect(Rails.logger).to receive(:error) do |message|
        expect(message).to include(standard_error.message)
      end
      expect { described_class.update!(params, headers, payload) }
        .to raise_error(standard_error)
    end

    it "logs the error and updates the event" do
      expect(Rails.logger).to receive(:error).with(/#{standard_error}/)

      expect { described_class.update!(params, headers, payload) }
        .to raise_error(standard_error)
    end

    it "records an error at the event level" do
      expect { described_class.update!(params, headers, payload) }
        .to raise_error(standard_error)
      expect(event.error).to eq("#{standard_error.class} : #{standard_error.message}")
      expect(event.info["failed_claim_id"]).to eq(claim_id)
      expect(event.info["error"]).to eq(standard_error.message)
      expect(event.info["error_class"]).to eq("StandardError")
      expect(event.info["error_backtrace"]).to be_present
    end
  end
end
