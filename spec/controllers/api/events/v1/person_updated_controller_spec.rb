# frozen_string_literal: true

RSpec.describe Api::Events::V1::PersonUpdatedController, :postgres, type: :controller do
  let!(:current_user) { User.authenticate! }
  let(:api_key) { ApiKey.create!(consumer_name: "Person Updated Tester") }
  let(:event_id) { SecureRandom.uuid }

  before(:each) do
    request.headers["Authorization"] = "Token #{api_key.key_string}"
  end

  let(:person) { FactoryBot.create(:person) }

  describe "before_action :check_api_disabled" do
    context "when API is disabled" do
      before do
        allow(FeatureToggle).to receive(:enabled?).with(:disable_person_updated_eventing).and_return(true)
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
        allow(FeatureToggle).to receive(:enabled?).with(:disable_person_updated_eventing).and_return(false)
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
      get :does_person_exist, params: { "participant_id": "NotAPerson" }
      expect(response.status).to eq 401
    end

    it "should be successful 204 when person does not exist" do
      get :does_person_exist, params: { "participant_id": "NotAPerson" }
      expect(response.status).to eq 204
    end

    it "should be successful 200 when person exists" do
      get :does_person_exist, params: { "participant_id": person.participant_id.to_s }
      expect(response.status).to eq 200
    end
  end

  describe "POST person updated" do
    let(:payload) { JSON.parse Events::PersonUpdated::PersonUpdatedEvent.example_response }
    let(:person_updated) { double(Events::PersonUpdated) }
    let(:attributes) { payload.slice(*Events::PersonUpdated::Attributes.members) }
    let(:is_veteran) { true }

    before do
      allow(Events::PersonUpdated).to receive(:new).with(
        payload["event_id"],
        payload["participant_id"],
        is_veteran,
        an_instance_of(
          Events::PersonUpdated::Attributes
        ).and(have_attributes(attributes))
      ).and_return(person_updated)
    end

    context "with a valid token" do
      it "returns 200 status response" do
        load_headers

        expect(person_updated).to receive(:call)

        post :person_updated, params: payload

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(JSON.dump({ "message": "PersonUpdated successfully processed" }))
      end
    end

    context "when event_id is already in Redis Cache" do
      before do
        allow(person_updated).to receive(:call).and_raise(
          Caseflow::Error::RedisLockFailed, "Lock failed"
        )
      end

      it "returns a 409 status and error message" do
        post :person_updated, params: payload
        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)).to eq({ "message" => "Lock failed" })
      end
    end

    context "when exception occurs" do
      before do
        allow(person_updated).to receive(:call).and_raise(StandardError, "Something went wrong")
      end

      it "returns a 422 status and error message" do
        post :person_updated, params: payload
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "message" => "Something went wrong" })
      end
    end
  end

  describe "POST #person_updated_error" do
    let(:params) do
      { event_id: event_id, errored_participant_id: 2, error: "some error" }
    end

    let(:person_error) { double(Events::PersonUpdatedError) }

    before do
      allow(Events::PersonUpdatedError).to receive(:new).with(
        event_id, 2, "some error"
      ).and_return(person_error)
    end

    context "when service error handling is successful" do
      it "returns a 201 status and success message" do
        expect(person_error).to receive(:call).and_return(:created)

        post :person_updated_error, params: params

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to eq(
          { "message" => "Person Updated Error Saved in Caseflow" }
        )
      end

      it "returns a 200 status and success message when event exists" do
        expect(person_error).to receive(:call).and_return(:updated)

        post :person_updated_error, params: params

        expect(response).to have_http_status(:ok)
      end
    end

    context "when RedisLockFailed error occurs" do
      before do
        allow(person_error).to receive(:call).and_raise(
          Caseflow::Error::RedisLockFailed, "Lock failed"
        )
      end

      it "returns a 409 status and error message" do
        post :person_updated_error, params: params

        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)).to eq({ "message" => "Lock failed" })
      end
    end

    context "when StandardError occurs" do
      before do
        allow(person_error).to receive(:call).and_raise(
          StandardError, "Something went wrong"
        )
      end

      it "returns a 422 status and error message" do
        post :person_updated_error, params: params

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
