# frozen_string_literal: true

describe Hearings::TranscriptionSettingsController, :all_dbs do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched"]) }

  before do
    @transcripton_contractor_1 = TranscriptionContractor.create!(
      id: 1,
      name: "First Contractor",
      directory: "directory name",
      email: "test1@va.gov",
      phone: "phone_number",
      poc: "contact"
    )
    @transcripton_contractor_2 = TranscriptionContractor.create!(
      id: 2,
      name: "Second Contractor",
      directory: "directory name",
      email: "test2@va.gov",
      phone: "phone_number",
      poc: "contact"
    )
  end

  context "GET index" do
    context "with JSON request" do
      context "an invalid transcription contractor ID" do
        subject { get :index, as: :json }
        it "returns json result" do
          response_body = JSON.parse(subject.body)
          expect(subject.status).to eq 200
          expect(response_body["transcription_contractors"][0]["id"]).to eq @transcripton_contractor_1.id
          expect(response_body["transcription_contractors"][1]["id"]).to eq @transcripton_contractor_2.id
        end
      end
    end

    context "with HTML request" do
      subject { get :index, as: :html }
      it "no JSON is returned`" do
        expect(subject.status).to eq 200
        expect(subject.body).to eq ""
      end
    end
  end

  context "GET show" do
    context "with JSON request" do
      context "an invalid transcription contractor ID" do
        subject { get :show, params: { id: 45 }, as: :json }
        it "redirects to 404 page" do
          expect(subject.status).to eq 302
          expect(subject).to redirect_to("/404")
        end
      end

      context "a valid transcription contractor ID" do
        subject { get :show, params: { id: 1 }, as: :json }
        it "returns json result" do
          response_body = JSON.parse(subject.body)
          expect(subject.status).to eq 200
          expect(response_body["transcription_contractor"]["id"]).to eq @transcripton_contractor_1.id
          expect(response_body["transcription_contractor"]["name"]).to eq @transcripton_contractor_1.name
          expect(response_body["transcription_contractor"]["directory"]).to eq @transcripton_contractor_1.directory
        end
      end
    end

    context "with HTML request" do
      subject { get :show, params: { id: 1 }, as: :html }
      it "no JSON is returned`" do
        expect(subject.status).to eq 200
        expect(subject.body).to eq ""
      end
    end
  end
end
