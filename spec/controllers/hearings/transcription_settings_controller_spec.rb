# frozen_string_literal: true

describe Hearings::TranscriptionSettingsController, :all_dbs do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched"]) }

  before do
    @transcripton_contractor = TranscriptionContractor.create!(
      id: 1, name: "Contractor", directory: "directory name"
    )
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
          expect(response_body["transcription_contractor"]["id"]).to eq @transcripton_contractor.id
          expect(response_body["transcription_contractor"]["name"]).to eq @transcripton_contractor.name
          expect(response_body["transcription_contractor"]["directory"]).to eq @transcripton_contractor.directory
        end
      end
    end

    context "with HTML request" do
      subject { get :show, params: { id: 1 }, as: :html }
      it "no JSON is returned" do
        expect(subject.status).to eq 200
        expect(subject.body).to eq ""
      end
    end
  end
end
