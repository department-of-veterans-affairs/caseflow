# frozen_string_literal: true

RSpec.describe "Correspondence Requests", :all_dbs, type: :request do
  let(:veteran) { create(:veteran, last_name: "Smith", file_number: "12345678") }
  let(:correspondence) { create(:correspondence, veteran_id: veteran.id, uuid: SecureRandom.uuid) }
  let(:current_user) { create(:intake_user) }

  before do
    FeatureToggle.enable!(:correspondence_queue)
    MailTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
  end

  describe "#current_step" do
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

    it "saves the user's current step in the intake form" do
      current_step = 1

      post queue_correspondence_intake_current_step_path(correspondence_uuid: correspondence.uuid), params: {
        correspondence_uuid: correspondence.uuid,
        current_step: current_step,
        redux_store: redux_store
      }

      correspondence = CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence)

      expect(response).to have_http_status(:success)
      expect(correspondence.current_step).to eq(current_step)
      expect(correspondence.redux_store).to eq(redux_store)
    end
  end

  describe "#process_intake" do
    let(:task_content) { "This is a test" }
    let(:post_data) do
      {
        tasks_not_related_to_appeal: [
          {
            klass: "DeathCertificateMailTask",
            assigned_to: "Colocated",
            content: task_content
          }
        ]
      }
    end

  describe "#process_intake" do
    let(:task_content) { "This is a test" }
    let(:post_data) do
      {
        mail_tasks: [
          {
            klass: "DeathCertificateMailTask",
            assigned_to: "Colocated",
            content: task_content
          }
        ]
      }
    end

    it "creates tasks not related to an appeal" do
      post queue_correspondence_intake_process_intake_path(correspondence_uuid: correspondence.uuid), params: {
        data: post_data
      }

      expect(response).to have_http_status(:created)
      expect(DeathCertificateMailTask.last.instructions).to eq([task_content])
    end
  end
end
