# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewCreatedController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:payload) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.example_response }

    context "with a valid token" do
      it "returns success response" do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        load_headers
        post :decision_review_created, params: JSON.parse(payload)
        expect(response).to have_http_status(:created)
      end

      it "returns ok response if record already exists and is completed" do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        load_headers
        2.times { post :decision_review_created, params: JSON.parse(payload) }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq("Record already exists in Caseflow")
      end
    end

    context "when claim_id is already in Redis Cache" do
      it "throws a Redis error and returns a 409 status" do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        load_headers
        redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
        lock_key = "RedisMutex:EndProductEstablishment:#{JSON.parse(payload)['claim_id']}"
        redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)
        post :decision_review_created, params: JSON.parse(payload)
        expect(response).to have_http_status(:conflict)
        redis.del(lock_key)
      end
    end

    context "with an invalid token" do
      it "returns unauthorized response" do
        request.headers["Authorization"] = "invalid_token"
        post :decision_review_created, params: JSON.parse(payload)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without a token" do
      it "returns unauthorized response" do
        # Omitting Authorization header to simulate missing token
        post :decision_review_created, params: JSON.parse(payload)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #decision_review_created_error" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "Appeals-Consumer") }
    let!(:appeals_consumer_paylod) { { "event_id": 3333, "errored_claim_id": 1345, "error": "this was an error" } }
    context "with an Authorized Token" do
      it "renders message Error Creating Decision Review and returns a method not allowed status" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error, params: appeals_consumer_paylod
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["message"]).to eq("Decision Review Created Error Saved in Caseflow")
      end
    end
    context "with an invalid Token" do
      it "returns unauthorized response" do
        request.headers["Authorization"] = "unAuthToken"
        post :decision_review_created_error
        expect(response).to have_http_status(:unauthorized)
      end
    end
    context "with no token" do
      it "returns unauthorized response" do
        # Omitting Authorization header to simulate missing token
        post :decision_review_created_error
        expect(response).to have_http_status(:unauthorized)
      end
    end
    context "catches errors" do
      it "raises a RedisLockFailed Error" do
        allow(Events::DecisionReviewCreatedError).to receive(:handle_service_error)
          .and_raise(Caseflow::Error::RedisLockFailed.new("Lock Failure"))
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error, params: appeals_consumer_paylod
        expect(response).to have_http_status(:conflict)
        expect(response.body).to eq({ message: "Lock Failure" }.to_json)
      end
      it "raises a Standard Error" do
        allow(Events::DecisionReviewCreatedError).to receive(:handle_service_error)
          .and_raise(StandardError.new("Standard Failure"))
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error, params: appeals_consumer_paylod
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq({ message: "Standard Failure" }.to_json)
      end
    end
  end

  describe "POST #decision_review_created_api disabled" do
    let(:api_key) { ApiKey.create!(consumer_name: "Appeals-Consumer") }
    let!(:payload) { Events::DecisionReviewCreated::DecisionReviewCreatedParser.example_response }
    let!(:appeals_consumer_paylod) { { "event_id": 3333, "errored_claim_id": 1345, "error": "this was an error" } }
    context "#contestable_issues with future ratings" do
      before { FeatureToggle.enable!(:disable_ama_eventing) }
      after { FeatureToggle.disable!(:disable_ama_eventing) }

      it "returns success response" do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        load_headers
        post :decision_review_created, params: JSON.parse(payload)
        expect(response).to have_http_status(:not_implemented)
        expect(response.body).to eq(
          '{"errors":[{"status":"501","title":"API is disabled","detail":"This endpoint is not supported."}]}'
        )
      end

      it "raises not_implemented status instead of process request with Redis error" do
        allow(Events::DecisionReviewCreatedError).to receive(:handle_service_error)
          .and_raise(Caseflow::Error::RedisLockFailed.new("Lock Failure"))
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error, params: appeals_consumer_paylod
        expect(response).to have_http_status(:not_implemented)
        expect(response.body).to eq(
          '{"errors":[{"status":"501","title":"API is disabled","detail":"This endpoint is not supported."}]}'
        )
      end

      it "raises not_implemented status instead of process request with standart error" do
        allow(Events::DecisionReviewCreatedError).to receive(:handle_service_error)
          .and_raise(StandardError.new("Standard Failure"))
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        post :decision_review_created_error, params: appeals_consumer_paylod
        expect(response).to have_http_status(:not_implemented)
        expect(response.body).to eq(
          '{"errors":[{"status":"501","title":"API is disabled","detail":"This endpoint is not supported."}]}'
        )
      end
    end
  end

  def json_payload
    JSON.parse(File.read(Rails.root.join("app",
                                         "services",
                                         "events",
                                         "decision_review_created",
                                         "decision_review_created_example.json")))
  end

  def load_headers
    request.headers["X-VA-Vet-SSN"] = "123456789"
    request.headers["X-VA-File-Number"] = "77799777"
    request.headers["X-VA-Vet-First-Name"] = "John"
    request.headers["X-VA-Vet-Last-Name"] = "Smith"
    request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
  end
end
