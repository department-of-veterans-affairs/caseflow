# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewCompletedController, type: :controller do
  let!(:current_user) { User.authenticate! }
  let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
  let(:event_id) { 1 }
  let(:fake_event_id) { 1738 }

  describe "before_action :check_api_disabled" do
    context "when API is disabled" do
      before do
        allow(FeatureToggle).to receive(:enabled?).with(:disable_ama_eventing).and_return(true)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      # rubocop:disable Layout/HashAlignment
      it "returns a 501 status and error message" do
        post :decision_review_completed, params: { event_id: event_id }
        expect(response).to have_http_status(:not_implemented)
        expect(JSON.parse(response.body)).to eq(
          "errors" => [
            {
              "status" => "501",
              "title"  => "API is disabled",
              "detail" => "This endpoint is not supported."
            }
          ]
        )
      end
      # rubocop:enable Layout/HashAlignment
    end

    context "when API is enabled" do
      before do
        allow(FeatureToggle).to receive(:enabled?).with(:disable_ama_eventing).and_return(false)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "allows the action to proceed" do
        expect(controller).to receive(:decision_review_completed)
        post :decision_review_completed, params: { event_id: event_id }
      end
    end
  end

  describe "POST #decision_review_completed" do
    let(:drc_params) { { event_id: event_id } }
    let(:event) { double("DecisionReviewCreatedEvent") }

    before do
      request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      allow(controller).to receive(:drc_params).and_return(drc_params)
    end

    context "when event exists" do
      before do
        allow(Event).to receive(:exists_and_is_completed?).with(event_id).and_return(true)
        allow(DecisionReviewCreatedEvent).to receive(:find_by).with(id: event_id).and_return(event)
      end

      context "when complete is successful" do
        before do
          load_headers
          allow(Events::DecisionReviewUpdated).to receive(:complete!).with(event, request.headers, drc_params)
        end

        # skipping this test until we implement complete! method
        xit "returns a 200 status and success message" do
          post :decision_review_completed, params: { event_id: event_id }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq(
            { "message" => "DecisionReviewCompletedEvent successfully processed" }
          )
        end
      end

      context "when RedisLockFailed error occurs" do
        before do
          allow(Events::DecisionReviewCompleted).to receive(:complete!).and_raise(
            Caseflow::Error::RedisLockFailed, "Lock failed"
          )
        end

        it "returns a 409 status and error message" do
          post :decision_review_completed, params: { event_id: event_id }
          expect(response).to have_http_status(:conflict)
          expect(JSON.parse(response.body)).to eq({ "message" => "Lock failed Record already exists in Caseflow" })
        end
      end

      context "when StandardError occurs" do
        before do
          allow(Events::DecisionReviewCompleted).to receive(:complete!).and_raise(StandardError, "Something went wrong")
        end

        it "returns a 422 status and error message" do
          post :decision_review_completed, params: { event_id: event_id }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({ "message" => "Something went wrong" })
        end
      end
    end
  end

  def load_headers
    request.headers["X-VA-Vet-SSN"] = "123456789"
    request.headers["X-VA-File-Number"] = "77799777"
    request.headers["X-VA-Vet-First-Name"] = "John"
    request.headers["X-VA-Vet-Last-Name"] = "Smith"
    request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
  end
end
