# frozen_string_literal: true

describe Hearings::TranscriptionFilesController, :all_dbs, type: :controller do
  let(:hearings_user) { create(:hearings_coordinator) }
  before { User.authenticate!(user: hearings_user) }
  describe "routes" do
    let!(:hearing) { create(:hearing, :with_transcription_files) }
    let(:transcription_file) { hearing.transcription_files.first }
    let(:options) { { format: :vtt, file_id: transcription_file.id } }
    subject { get :download_transcription_file, params: options }

    it "downloading file" do
      subject
      expect(response.status).to eq(302)
    end

    context "when not a hearings user" do
      let(:vso_user) { create(:user, :vso_role) }
      before do
        User.unauthenticate!
        User.authenticate!(user: vso_user)
      end
      it "downloading a file" do
        subject
        expect(response).to redirect_to("/unauthorized")
      end
    end
  end
end
