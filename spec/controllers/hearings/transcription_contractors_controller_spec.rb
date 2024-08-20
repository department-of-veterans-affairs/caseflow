# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hearings::TranscriptionContractorsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched"]) }
  let!(:transcription_contractor_1) { create(:transcription_contractor) }
  let!(:transcription_contractor_2) { create(:transcription_contractor) }
  let(:error_response) do
    {
      errors: [
        title: "Contractor Not Found",
        detail: "Contractor with that ID is not found"
      ]
    }
  end
  let(:seed_transcriptions) do
    create(:transcription,
           transcription_contractor: transcription_contractor_1,
           sent_to_transcriber_date: Time.zone.today.beginning_of_week.yesterday)

    create(:transcription,
           transcription_contractor: transcription_contractor_1,
           sent_to_transcriber_date: Time.zone.today.beginning_of_week.tomorrow)

    create(:transcription,
           transcription_contractor: transcription_contractor_1,
           sent_to_transcriber_date: Time.zone.today.next_week)

    create(:transcription,
           transcription_contractor: transcription_contractor_2,
           sent_to_transcriber_date: Time.zone.today.beginning_of_week.tomorrow)
  end

  let(:transcription_contractor_counts_this_week) { [2, 1] }
  let(:transcription_contractor_counts_next_week) { [1, 0] }

  before do
    TranscriptionTeam.singleton.add_user(user)
  end

  describe "GET index" do
    it "returns blank when requesting HTML" do
      get :index
      expect(response.status).to eq 200
      expect(response.body).to eq ""
    end
    it "returns a JSON list of contractors when requesting JSON" do
      Transcription.all
      get :index, as: :json
      test_response = { transcription_contractors:
                        [{
                          **transcription_contractor_1.as_json,
                          transcription_count_this_week: 0
                        }, {
                          **transcription_contractor_2.as_json,
                          transcription_count_this_week: 0
                        }] }
      expect(response.status).to eq 200
      expect(response.body).to eq test_response.to_json
    end
    it "returns the correct trascription counts for each contractor for this week" do
      allow(Time.zone).to receive(:today).and_return(Time.zone.today.end_of_week.yesterday)
      seed_transcriptions
      get :index, as: :json
      response_counts = JSON.parse(response.body)["transcription_contractors"].pluck("transcription_count_this_week")
      expect(response.status).to eq 200
      expect(response_counts).to eq transcription_contractor_counts_this_week
    end
    it "returns the correct trascription counts for each contractor for next week" do
      allow(Time.zone).to receive(:today).and_return(Time.zone.today.end_of_week.yesterday)
      seed_transcriptions
      allow(Time.zone).to receive(:today).and_return(Time.zone.today.next_week.end_of_week.yesterday)
      get :index, as: :json
      response_counts = JSON.parse(response.body)["transcription_contractors"].pluck("transcription_count_this_week")
      expect(response.status).to eq 200
      expect(response_counts).to eq transcription_contractor_counts_next_week
    end
  end

  describe "GET show" do
    it "returns the contractor matching the ID" do
      get :show, params: { id: transcription_contractor_1.id }
      test_response = { transcription_contractor: transcription_contractor_1 }
      expect(response.status).to eq 200
      expect(response.body).to eq test_response.to_json
    end
    it "returns an error for an invalid ID" do
      get :show, params: { id: 1950 }
      expect(response.status).to eq 404
      expect(response.body).to eq error_response.to_json
    end
  end

  describe "POST create" do
    it "creates a new transcription contractor and returns it when using valid params" do
      params = {
        transcription_contractor: {
          name: "New Name",
          directory: "directory",
          email: "test@va.gov",
          phone: "phone",
          poc: "person of contact"
        }
      }
      post :create, params: params
      test_response = {
        transcription_contractor: TranscriptionContractor.last
      }
      expect(response.status).to eq 201
      expect(response.body).to eq test_response.to_json
    end

    it "returns an error for missing params" do
      post :create
      expect(response.status).to eq 404
      expect(response.body).to eq error_response.to_json
    end

    it "returns validation errors for invalid params" do
      params = { transcription_contractor: { directory: "test" } }
      post :create, params: params
      test_response = {
        errors: [
          title: "ActiveRecord::RecordInvalid",
          detail: "Validation failed: Email can't be blank, Name can't be blank, " \
            "Phone can't be blank, Poc can't be blank"
        ]
      }
      expect(response.status).to eq 400
      expect(response.body).to eq test_response.to_json
    end
  end

  describe "PATCH update" do
    it "returns validation errors for invalid params" do
      params = { id: transcription_contractor_1.id, transcription_contractor: { directory: "" } }
      patch :update, params: params
      test_response = {
        errors: [
          title: "ActiveRecord::RecordInvalid",
          detail: "Validation failed: Directory can't be blank"
        ]
      }
      expect(response.status).to eq 400
      expect(response.body).to eq test_response.to_json
    end

    it "returns an updated transcription contractor for valid params" do
      params = { id: transcription_contractor_1.id, transcription_contractor: { directory: "new directory" } }
      patch :update, params: params
      expect(response.status).to eq 202
      expect(JSON.parse(response.body)["transcription_contractor"]["directory"]).to eq "new directory"
    end
  end

  describe "DELETE destroy" do
    it "soft deletes a record for a valid ID" do
      delete :destroy, params: { id: transcription_contractor_1.id }
      expect(response.status).to eq 200
      expect(response.body).to eq "{}"
      expect(TranscriptionContractor.where(id: transcription_contractor_1.id).count).to eq 0
      expect(TranscriptionContractor.with_deleted.where(id: transcription_contractor_1.id).count).to eq 1
    end
    it "returns an error for an invalid ID" do
      delete :destroy, params: { id: 1950 }
      expect(response.status).to eq 404
      expect(response.body).to eq error_response.to_json
    end
  end

  before do
    transcription_contractor_2.update!(is_available_for_work: true)
  end

  describe "available contractors" do
    it "only gives available contractors" do
      get :available_contractors

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["transcription_contractors"]).to eq(
        [{
          "id": transcription_contractor_2.id,
          "name": "Contractor Name"
        }.transform_keys(&:to_s)]
      )
    end

    it "gives the correct dates excluding holidays" do
      allow(Time.zone).to receive(:today).and_return Date.new(2024, 8, 20)
      get :available_contractors

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["return_dates"]).to eq(["09/05/2024", "08/25/2024"])
    end
  end
end
