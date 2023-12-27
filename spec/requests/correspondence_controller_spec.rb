# frozen_string_literal: true

RSpec.describe "Correspondence Requests", :all_dbs, type: :request do
  let(:veteran) { create(:veteran, last_name: "Smith", file_number: "12345678") }
  let(:correspondence) { create(:correspondence, veteran_id: veteran.id, uuid: SecureRandom.uuid) }
  let(:current_user) { create(:intake_user) }

  let(:redux_store) do
    {
      taskRelatedAppealIds: [],
      newAppealRelatedTasks: [],
      fetchedAppeals: [],
      correspondences: [],
      radioValue: '0',
      relatedCorrespondences: [],
      mailTasks: {},
      unrelatedTasks: [],
      currentCorrespondence: {
        id: 181,
        veteran_id: 3909
      },
      veteranInformation: {
        id: 3909
      },
      waivedEvidenceTasks: []
    }.to_json
  end

  before do
    FeatureToggle.enable!(:correspondence_queue)
    MailTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
  end

  describe "#current_step" do
    it "saves the user's current step in the intake form" do
      current_step = 1

      post queue_correspondence_intake_current_step_path(correspondence_uuid: correspondence.uuid), params: {
        correspondence_uuid: correspondence.uuid,
        current_step: current_step,
        redux_store: redux_store
      }

      expect(response).to have_http_status(:success)
      expect(CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence).current_step).to eq(current_step)
      expect(CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence).redux_store).to eq(redux_store)
    end
  end
end
