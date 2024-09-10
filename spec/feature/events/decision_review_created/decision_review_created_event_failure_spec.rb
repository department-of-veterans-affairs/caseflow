# frozen_string_literal: true

RSpec.describe Api::Events::V1::DecisionReviewCreatedController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:payload) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.example_response }
    let(:parser) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.load_example }

    # Each context will load the payload and then overwrite certain values with "nil" to simulate missing data
    context "when there are invalid top level params" do
      it "raises an error when trying to create a User" do
        hash = JSON.parse(payload)
        hash["css_id"] = nil
        hash["station"] = nil
        load_headers
        post :decision_review_created, params: hash, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(EventRecord.count).to eq(0)
        expect(Event.count).to eq(1)
        event = Event.last
        expect(event.error).to include("DecisionReviewCreatedUserError")
      end
    end

    context "when there are missing Veteran params" do
      it "raises an error when trying to create a Veteran" do
        hash = JSON.parse(payload)
        load_headers
        request.headers["X-VA-Vet-SSN"] = nil
        request.headers["X-VA-File-Number"] = nil
        post :decision_review_created, params: hash, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(EventRecord.count).to eq(0)
        expect(Event.count).to eq(1)
        event = Event.last
        expect(event.error).to include("DecisionReviewCreatedVeteranError")
      end
    end

    context "when there are missing ClaimReview params (veteran_file_number)" do
      it "raises an error when trying to create a ClaimReview" do
        hash = JSON.parse(payload)
        load_headers
        request.headers["X-VA-File-Number"] = nil
        post :decision_review_created, params: hash, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(EventRecord.count).to eq(0)
        expect(Event.count).to eq(1)
        event = Event.last
        # failure occurs when trying to create Veteran, which happens in an earlier step than ClaimReview
        expect(event.error).to include("DecisionReviewCreatedVeteranError")
      end
    end

    context "when there are missing Claimant params" do
      it "raises an error when trying to create a Claimant" do
        hash = JSON.parse(payload)
        load_headers
        hash["claim_review"]["veteran_is_not_claimant"] = true
        hash["claimant"]["participant_id"] = nil
        post :decision_review_created, params: hash, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(EventRecord.count).to eq(0)
        expect(Event.count).to eq(1)
        event = Event.last
        expect(event.error).to include("DecisionReviewCreatedClaimantError")
      end
    end

    context "when there is bad data in Intake params" do
      it "raises an error when trying to create an Intake" do
        hash = JSON.parse(payload)
        load_headers
        hash["intake"]["type"] = 999
        post :decision_review_created, params: hash, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(EventRecord.count).to eq(0)
        expect(Event.count).to eq(1)
        event = Event.last
        expect(event.error).to include("DecisionReviewCreatedIntakeError")
      end
    end

    context "when there are missing EPE params" do
      it "raises an error when trying to create an EPE" do
        hash = JSON.parse(payload)
        load_headers
        hash["end_product_establishment"]["payee_code"] = nil
        post :decision_review_created, params: hash, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(EventRecord.count).to eq(0)
        expect(Event.count).to eq(1)
        event = Event.last
        expect(event.error).to include("DecisionReviewCreatedEpEstablishmentError")
      end
    end

    context "when there are missing Request Issue params" do
      it "raises an error when trying to create Request Issues" do
        hash = JSON.parse(payload)
        load_headers
        hash["request_issues"][0]["benefit_type"] = nil
        post :decision_review_created, params: hash, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(EventRecord.count).to eq(0)
        expect(Event.count).to eq(1)
        event = Event.last
        expect(event.error).to include("DecisionReviewCreatedRequestIssuesError")
      end
    end
  end
end

def load_headers
  request.headers["Authorization"] = "Token token=#{api_key.key_string}"
  request.headers["X-VA-Vet-SSN"] = "123456789"
  request.headers["X-VA-File-Number"] = "77799777"
  request.headers["X-VA-Vet-First-Name"] = "John"
  request.headers["X-VA-Vet-Last-Name"] = "Smith"
  request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
end
