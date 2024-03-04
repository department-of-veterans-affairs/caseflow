# frozen_string_literal: true

RSpec.describe "Correspondence Requests", :all_dbs, type: :request do
  let(:current_user) { create(:intake_user) }
  let!(:parent_task) { create(:correspondence_intake_task, appeal: correspondence, assigned_to: current_user) }
  let(:correspondence) do
    create(
      :correspondence
    )
  end

  let(:mock_doc_uploader) { instance_double(CorrespondenceDocumentsEfolderUploader) }

  before do
    FeatureToggle.enable!(:correspondence_queue)
    MailTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)

    allow(CorrespondenceDocumentsEfolderUploader).to receive(:new).and_return(mock_doc_uploader)
    allow(mock_doc_uploader).to receive(:upload_documents_to_claim_evidence).and_return(true)
  end

  describe "#current_step" do
    let(:redux_store) do
      {
        taskRelatedAppealIds: [],
        newAppealRelatedTasks: [],
        fetchedAppeals: [],
        correspondences: [],
        radioValue: "0",
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
      correspondence = create(
        :correspondence
      )

      post queue_correspondence_intake_current_step_path(correspondence_uuid: correspondence.uuid), params: {
        correspondence_uuid: correspondence.uuid,
        current_step: current_step,
        redux_store: redux_store
      }

      expect(response).to have_http_status(:success)

      intake_correspondence = CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence)
      expect(intake_correspondence.current_step).to eq(current_step)
      expect(intake_correspondence.redux_store).to eq(redux_store)
    end
  end

  describe "correspondence_cases" do
    before do
      get correspondence_path, as: :json
    end

    it "returns 200 status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns json in the expected shape for correspondence_cases" do
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data[:correspondence_config][:table_title]).to be_a(String)
      expect(data[:correspondence_config]).to be_a(Hash)
      expect(data[:correspondence_config][:active_tab]).to be_a(String)
      expect(data[:correspondence_config][:tasks_per_page]).to be_a(Integer)
      expect(data[:correspondence_config][:use_task_pages_api?]).to eq(nil).or be_a(TrueClass || FalseClass)
      expect(data[:correspondence_config][:tabs]).to be_a(Array)

      data[:correspondence_config][:tabs].each do |tab|
        expect(tab[:label]).to be_a(String)
        expect(tab[:name]).to be_a(String)
        expect(tab[:description]).to be_a(String)
        expect(tab[:columns]).to be_a(Array)
        expect(tab[:defaultSort]).to be_a(Hash)
        expect(tab[:tasks]).to be_a(Array)

        tab[:tasks]&.each do |task|
          expect(task[:attributes]).to be_a(Hash)
          expect(task[:attributes][:unique_id]).to be_a(String)
          expect(task[:attributes][:instructions]).to be_a(Array)
          expect(task[:attributes][:veteran_details]).to be_a(String)
          expect(task[:attributes][:completion_date]).to eq(nil).or be_a(String)
          expect(task[:attributes][:days_waiting]).to be_a(Integer)
          expect(task[:attributes][:va_date_of_receipt]).to be_a(String)
          expect(task[:attributes][:label]).to be_a(String)
          expect(task[:attributes][:status]).to be_a(String)
          expect(task[:attributes][:assigned_to]).to be_a(Hash)
          expect(task[:attributes][:assigned_by]).to be_a(Hash)
        end
      end
    end
  end

  describe "correspondence_team" do
    before do
      MailTeamSupervisor.singleton.add_user(current_user)
      get correspondence_team_path, as: :json
    end

    it "returns 200 status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns json in the expected shape correspondence_team" do
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data[:correspondence_config][:table_title]).to be_a(String)
      expect(data[:correspondence_config]).to be_a(Hash)
      expect(data[:correspondence_config][:active_tab]).to be_a(String)
      expect(data[:correspondence_config][:tasks_per_page]).to be_a(Integer)
      expect(data[:correspondence_config][:use_task_pages_api?]).to eq(nil).or be_a(TrueClass || FalseClass)
      expect(data[:correspondence_config][:tabs]).to be_a(Array)

      data[:correspondence_config][:tabs].each do |tab|
        expect(tab[:label]).to be_a(String)
        expect(tab[:name]).to be_a(String)
        expect(tab[:description]).to be_a(String)
        expect(tab[:columns]).to be_a(Array)
        expect(tab[:defaultSort]).to be_a(Hash)
        expect(tab[:tasks]).to be_a(Array)

        tab[:tasks]&.each do |task|
          expect(task[:attributes]).to be_a(Hash)
          expect(task[:attributes][:unique_id]).to be_a(String)
          expect(task[:attributes][:instructions]).to be_a(Array)
          expect(task[:attributes][:veteran_details]).to be_a(String)
          expect(task[:attributes][:completion_date]).to eq(nil).or be_a(String)
          expect(task[:attributes][:days_waiting]).to be_a(Integer)
          expect(task[:attributes][:va_date_of_receipt]).to be_a(String)
          expect(task[:attributes][:label]).to be_a(String)
          expect(task[:attributes][:status]).to be_a(String)
          expect(task[:attributes][:assigned_to]).to be_a(Hash)
          expect(task[:attributes][:assigned_by]).to be_a(Hash)
        end
      end
    end
  end

  describe "#process_intake" do
    context "tasks_not_related_to_appeal" do
      shared_examples "successful unrelated task creation" do |klass_name, assignee|
        context klass_name.to_s do
          let(:task_content) { "This is a test" }
          let(:post_data) do
            {
              tasks_not_related_to_appeal: [
                {
                  klass: klass_name,
                  assigned_to: assignee,
                  content: task_content
                }
              ]
            }
          end

          it "creates tasks not related to an appeal" do
            expect do
              post queue_correspondence_intake_process_intake_path(correspondence_uuid: correspondence.uuid),
                   params: post_data
            end.to change(Task, :count)

            expect(response).to have_http_status(:created)

            created = Task.last
            expect(created.instructions).to eq([task_content])
          end
        end
      end

      unrelated_task_types = {
        "CavcCorrespondenceMailTask": "CavcLitigationSupport",
        "CongressionalInterestMailTask": "LitigationSupport",
        "DeathCertificateMailTask": "Colocated",
        "FoiaRequestMailTask": "PrivacyTeam",
        "OtherMotionMailTask": "LitigationSupport",
        "PowerOfAttorneyRelatedMailTask": "HearingAdmin",
        "PrivacyActRequestMailTask": "PrivacyTeam",
        "PrivacyComplaintMailTask": "PrivacyTeam",
        "StatusInquiryMailTask": "LitigationSupport"
      }

      unrelated_task_types.each do |klass_name, assignee|
        it_should_behave_like "successful unrelated task creation", klass_name, assignee
      end
    end

    context "mail_tasks" do
      shared_examples "successful mail task creation" do |task_name, class_name|
        context task_name.to_s do
          it "creates a new mail task of the given type" do
            expect do
              post queue_correspondence_intake_process_intake_path(correspondence_uuid: correspondence.uuid), params: {
                mail_tasks: [task_name]
              }
            end.to change(Task, :count)

            expect(response).to have_http_status(:created)

            created = Task.last
            expect(created.status).to eq("completed")
            expect(created.type).to eq(class_name)
            expect(created.assigned_to_id).to eq(current_user.id)
            expect(created.assigned_to_type).to eq(User.name)
          end
        end
      end

      mail_tasks = {
        "Associated with Claims Folder": AssociatedWithClaimsFolderMailTask.name,
        "Change of address": AddressChangeMailTask.name,
        "Evidence or argument": EvidenceOrArgumentMailTask.name,
        "Returned or undeliverable mail": ReturnedUndeliverableCorrespondenceMailTask.name,
        "Sent to ROJ": SentToRojMailTask.name,
        "VACOLS updated": VacolsUpdatedMailTask.name
      }

      mail_tasks.each do |task_type, class_name|
        it_should_behave_like "successful mail task creation", task_type, class_name
      end
    end
  end
end
