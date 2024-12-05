# frozen_string_literal: true

RSpec.describe HearingsApplicationController, :postgres, type: :controller do
  context "when user is not authenticated" do
    it "redirects" do
      get :index
      expect(response.status).to eq 302
    end
  end

  context "when user does not have correct permissions" do
    before do
      User.authenticate!(roles: ["Wrong Role"])
    end
    it "redirects" do
      get :index
      expect(response.status).to eq 302
    end
  end

  context "when user has build hearsched permissions" do
    before do
      User.authenticate!(roles: ["Build HearSched"])
    end
    it "returns a successful response" do
      get :build_schedule_index
      expect(response.status).to eq 200
    end
    it "returns a successful response" do
      get :index
      expect(response.status).to eq 200
    end
  end

  context "when user has edit hearsched permissions" do
    before do
      User.authenticate!(roles: ["Edit HearSched"])
    end
    it "redirects" do
      get :build_schedule_index
      expect(response.status).to eq 302
    end
    it "returns a successful response" do
      get :index
      expect(response.status).to eq 200
    end
  end

  context "when user reader permissions" do
    let!(:user) { User.authenticate!(roles: ["Reader", "Hearing Prep", "Edit HearSched", "Build HearSched"]) }

    it "returns a succcessful response" do
      get :show_hearing_worksheet_index, params: { hearing_id: 1 }
      expect(response.status).to eq 200
    end
  end

  context "when user has transcriptions permissions" do
    let!(:user) { User.authenticate!(roles: ["Transcriptions"]) }

    it "returns a succcessful response when part of transcriptions team" do
      TranscriptionTeam.singleton.add_user(user)
      get :transcription_file_dispatch
      expect(response.status).to eq 200
    end
  end

  context "when user has VSO role" do
    before do
      TrackVeteranTask.create!(appeal: hearing.appeal, parent: hearing.appeal.root_task, assigned_to: vso_org)
    end

    let!(:hearing) { create(:hearing, :with_completed_tasks) }
    let!(:participant_id) { "12345" }
    let!(:vso_org) { create(:vso, name: "VSO", role: "VSO", participant_id: participant_id) }
    let!(:vso_user) { create(:user, :vso_role, email: "email@email.com") }

    before { User.authenticate!(roles: ["VSO"]) }

    context "Whenever VSO user represents case" do
      before do
        allow_any_instance_of(User).to receive(:vsos_user_represents).and_return(
          [{ participant_id: participant_id }]
        )
      end

      it "GET show_hearing_worksheet_index redirects" do
        get :show_hearing_worksheet_index, params: { hearing_id: hearing.uuid }
        expect(response.status).to eq 302
      end

      it "GET hearings details page returns a successful response" do
        get :show_hearing_details_index, params: { hearing_id: hearing.uuid }
        expect(response.status).to eq 200
      end
    end

    context "Whenever VSO user does not represent case" do
      before do
        allow_any_instance_of(User).to receive(:vsos_user_represents).and_return(
          [{ participant_id: "something-different" }]
        )
      end

      it "GET hearings details page returns a redirect to /unauthorized" do
        get :show_hearing_details_index, params: { hearing_id: hearing.uuid }
        expect(response.status).to eq 302
        expect(response).to redirect_to "/unauthorized"
      end
    end
  end
end
