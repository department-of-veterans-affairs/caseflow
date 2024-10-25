# frozen_string_literal: true

RSpec.describe Api::Events::V1::PersonUpdatedController, :postgres, type: :controller do
  let!(:current_user) { User.authenticate! }
  let(:api_key) { ApiKey.create!(consumer_name: "Person Updated Tester") }
  let(:event_id) { 1 }
  let(:fake_event_id) { 1738 }

  before(:each) do
    request.headers["Authorization"] = "Token #{api_key.key_string}"
  end

  let(:person) { FactoryBot.create(:person) }

  describe "before_action :check_api_disabled" do
    context "when API is disabled" do
      before do
        allow(FeatureToggle).to receive(:enabled?).with(:disable_ama_eventing).and_return(true)
      end

      it "returns a 501 status and error message" do
        post :person_updated, params: { event_id: event_id }
        expect(response).to have_http_status(:not_implemented)
        expect(JSON.parse(response.body)).to eq(
          "errors" => [
            {
              "status" => "501",
              "title" => "API is disabled",
              "detail" => "This endpoint is not supported."
            }
          ]
        )
      end
    end

    context "when API is enabled" do
      before do
        allow(FeatureToggle).to receive(:enabled?).with(:disable_ama_eventing).and_return(false)
      end

      it "allows the action to proceed" do
        expect(controller).to receive(:person_updated)
        post :person_updated, params: { event_id: event_id }
      end
    end
  end

  describe "POST does person exist" do
    it "should not be successful due to unauthorized request" do
      # set up the wrong token
      request.headers["Authorization"] = "BADTOKEN"
      post :does_person_exist, params: { "participant_id": "NotAPerson" }
      expect(response.status).to eq 401
    end

    it "should be successful 204 when person does not exist" do
      post :does_person_exist, params: { "participant_id": "NotAPerson" }
      expect(response.status).to eq 204
    end

    it "should be successful 200 when person exists" do
      post :does_person_exist, params: { "participant_id": person.participant_id.to_s }
      expect(response.status).to eq 200
    end
  end

  describe "POST person updated" do
    let!(:payload) { Events::PersonUpdated::PersonUpdatedEvent.example_response }

    context "with a valid token" do
      it "returns 200 status response" do
        load_headers

        post :person_updated, params: JSON.parse(payload)

        expect(response).to have_http_status(:created)
      end
    end

    context "when event_id is already in Redis Cache" do
      it "throws a Redis error and returns a 409 status" do
        load_headers

        redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
        lock_key = "RedisMutex:PersonUpdated:#{payload['event_id']}"
        redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)

        post :person_updated, params: payload
        expect(response).to have_http_status(:conflict)
        redis.del(lock_key)
      end
    end

    context "when exception occurs" do
      before do
        allow(Person).to receive(:update!).and_raise(StandardError, "Something went wrong")
      end

      it "returns a 422 status and error message" do
        post :person_updated, params: { event_id: event_id }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "message" => "Something went wrong" })
      end
    end
  end

  describe "POST #person_updated_error" do
    let(:pu_error_params) do
      { event_id: event_id, errored_participant_id: 2, error: "some error" }
    end

    before do
      allow(controller).to receive(:pu_error_params).and_return(pu_error_params)
    end

    context "when service error handling is successful" do
      let(:person_error) { double(Events::PersonUpdatedError) }

      before do
        allow(Events::PersonUpdatedError).to receive(:new).with(
          event_id, 2, "some error"
        ).and_return(person_error)
      end

      it "returns a 201 status and success message" do
        post :person_updated_error, params: { event_id: event_id }

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to eq(
          { "message" => "Person Updated Error Saved in Caseflow" }
        )
      end
    end

    context "when RedisLockFailed error occurs" do
      before do
        allow(person_error).to receive(:call).and_raise(
          Caseflow::Error::RedisLockFailed, "Lock failed"
        )
      end

      it "returns a 409 status and error message" do
        post :person_updated_error, params: { event_id: event_id }

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)).to eq({ "message" => "Lock failed" })
      end
    end

    context "when StandardError occurs" do
      before do
        allow(person_error).to receive(:handle_service_error).and_raise(
          StandardError, "Something went wrong"
        )
      end

      it "returns a 422 status and error message" do
        post :person_updated_error, params: { event_id: event_id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "message" => "Something went wrong" })
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
