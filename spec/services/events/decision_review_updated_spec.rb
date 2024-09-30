# frozen_string_literal: true

describe Events::DecisionReviewUpdated do
  let(:consumer_event_id) { "1234567890" }
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
  let(:params) { { consumer_event_id: consumer_event_id } }
  let(:headers) { {} }
  let(:payload) { {} }
  let(:user) { double("User") }
  let(:end_product_establishment) do
    double("EndProductEstablishment", source: review)
  end

  before do
    allow(DecisionReviewUpdatedEvent).to receive(:find_or_create_by)
      .with(reference_id: consumer_event_id).and_return(event)
    allow(Events::DecisionReviewUpdated::DecisionReviewUpdatedParser).to receive(:new)
      .with(headers, payload).and_return(parser)
    allow(Events::CreateUserOnEvent).to receive(:handle_user_creation_on_event)
      .with(event: event, css_id: parser.css_id, station_id: parser.station_id).and_return(user)
    allow(EndProductEstablishment).to receive(:find_by)
      .with(reference_id: parser.end_product_establishment_reference_id).and_return(end_product_establishment)
    allow(Events::DecisionReviewUpdated::UpdateInformalConference).to receive(:process!)
      .with(event: event, parser: parser).and_return(nil)
    allow(Events::DecisionReviewUpdated::UpdateClaimReview).to receive(:process!)
      .with(event: event, parser: parser).and_return(nil)
    allow(Events::DecisionReviewUpdated::UpdateEndProductEstablishment).to receive(:process!)
      .with(event: event, parser: parser).and_return(nil)
    allow(RequestIssuesUpdateEvent).to receive(:new)
      .with(user: user, review: review, parser: parser).and_return(double("RequestIssuesUpdateEvent", perform!: nil))
  end

  describe ".update!" do
    it "finds or creates an event" do
      expect(DecisionReviewUpdatedEvent).to receive(:find_or_create_by).with(reference_id: consumer_event_id)
      Events::DecisionReviewUpdated.update!(params, headers, payload)
    end

    it "creates a user" do
      expect(Events::CreateUserOnEvent).to receive(:handle_user_creation_on_event)
        .with(event: event, css_id: parser.css_id, station_id: parser.station_id)
      Events::DecisionReviewUpdated.update!(params, headers, payload)
    end

    it "finds an end product establishment" do
      expect(EndProductEstablishment).to receive(:find_by)
        .with(reference_id: parser.end_product_establishment_reference_id)
      Events::DecisionReviewUpdated.update!(params, headers, payload)
    end

    it "updates informal conference" do
      expect(Events::DecisionReviewUpdated::UpdateInformalConference).to receive(:process!)
        .with(event: event, parser: parser)
      Events::DecisionReviewUpdated.update!(params, headers, payload)
    end

    it "updates claim review" do
      expect(Events::DecisionReviewUpdated::UpdateClaimReview).to receive(:process!).with(event: event, parser: parser)
      Events::DecisionReviewUpdated.update!(params, headers, payload)
    end

    it "updates end product establishment" do
      expect(Events::DecisionReviewUpdated::UpdateEndProductEstablishment).to receive(:process!)
        .with(event: event, parser: parser)
      Events::DecisionReviewUpdated.update!(params, headers, payload)
    end

    it "updates request issues" do
      expect(RequestIssuesUpdateEvent).to receive(:new)
        .with(user: user, review: review, parser: parser).and_return(double("RequestIssuesUpdateEvent", perform!: nil))
      Events::DecisionReviewUpdated.update!(params, headers, payload)
    end

    it "updates the event" do
      expect(event).to receive(:update!)
      Events::DecisionReviewUpdated.update!(params, headers, payload)
    end
  end
end
