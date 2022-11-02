# frozen_string_literal: true

RSpec.describe SplitAppealController, type: :controller do
  describe "POST split_appeal" do
    let(:ssc_user) { create(:user, roles: "{Hearing Prep,Reader,SPLTAPPLLANNISTER}") }

    before do
      User.authenticate!(user: ssc_user)
      FeatureToggle.enable!(:split_appeal_workflow)
    end

    context "with valid parameters create a appeal with 3 request issues" do
      let(:root_task) { RootTask.find(create(:root_task).id) }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:request_issue2) { create(:request_issue, benefit_type: benefit_type1) }
      let(:benefit_type1) { "compensation" }
      let(:request_issue3) { create(:request_issue, benefit_type: benefit_type2) }
      let(:benefit_type2) { "pension" }
      let(:appeal) { create(
        :appeal, tasks: [root_task],
        request_issues: [request_issue, request_issue2, request_issue3]
        ) }
      let(:valid_params) do
        {
          appeal_id: appeal.id,
          appeal_split_issues: { request_issue.id => true },
          split_reason: "Include a motion for CUE with respect to a prior Board decision",
          split_other_reason: "",
          user_css_id: ssc_user.css_id
        }
      end

      it "creates a new split appeal" do
        post :split_appeal, params: valid_params
        expect(response.status).to eq 201
        dup_appeal = Appeal.last
        expect(appeal.stream_docket_number).to eq(dup_appeal.stream_docket_number)
        expect(appeal.veteran_file_number).to eq(dup_appeal.veteran_file_number)
      end

      it "creates a split record for SplitCorrelationTable in DB and tasks" do
        post :split_appeal, params: valid_params
        dup_appeal = Appeal.last
        appeal_type = dup_appeal.docket_type,
        appeal_uuid = dup_appeal.uuid,
        created_at = Time.zone.now.utc,
        created_by_id = current_user.id,
        original_appeal_id = appeal.id,
        original_appeal_uuid = appeal.uuid,
        original_request_issue_ids = [request_issue.id, request_issue2.id, request_issue3.id],
        relationship_type = "split_appeal",
        split_other_reason = split_other_reason,
        split_reason = split_reason,
        split_request_issue_ids = [],
        updated_at = Time.zone.now.utc,
        updated_by_id = current_user.id,
        working_split_status = Constants.TASK_STATUSES.in_progress
        appeal_split_task = appeal.tasks.where(type: "SplitAppealTask").first
        dup_split_task = dup_appeal.tasks.where(type: "SplitAppealTask").first
        SCT = SplitCorrelationTable.last
        expect(SCT.appeal_id).to eq(dup_appeal.id)
        expect(SCT.original_request_issue_ids).to eq([request_issue3.id, request_issue2.id, request_issue.id])
        expect(SCT.original_appeal_id).to eq(appeal.id)
        expect(appeal.tasks.where(type: "SplitAppealTask").count).to eq(1)
        expect(appeal_split_task.parent_id).to eq(appeal.root_task.id)
        expect(appeal_split_task.instructions).to eq([valid_params[:split_reason]])
        expect(appeal_split_task.status).to eq("completed")
        expect(dup_appeal.tasks.where(type: "SplitAppealTask").count).to eq(1)
        expect(dup_split_task.parent_id).to eq(dup_appeal.root_task.id)
        expect(dup_split_task.appeal_id).to eq(dup_appeal.id)
      end
    end

    context "split_other_reason record saves" do
      let(:root_task) { RootTask.find(create(:root_task).id) }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:request_issue2) { create(:request_issue, benefit_type: benefit_type1) }
      let(:benefit_type1) { "compensation" }
      let(:request_issue3) { create(:request_issue, benefit_type: benefit_type2) }
      let(:benefit_type2) { "pension" }
      let(:appeal) { create(
        :appeal,
        tasks: [root_task],
        request_issues: [request_issue, request_issue2, request_issue3]
        ) }
      let(:valid_params) do
        {
          appeal_id: appeal.id,
          appeal_split_issues: { request_issue.id => true },
          split_reason: "other",
          split_other_reason: "Some Other Reason",
          user_css_id: ssc_user.css_id
        }
      end

      it "creates a new split appeal" do
        post :split_appeal, params: valid_params
        expect(response.status).to eq 201
        dup_appeal = Appeal.last
        expect(appeal.stream_docket_number).to eq(dup_appeal.stream_docket_number)
        expect(appeal.veteran_file_number).to eq(dup_appeal.veteran_file_number)
      end

      it "creates a split record for SplitCorrelationTable in DB and tasks" do
        post :split_appeal, params: valid_params
        dup_appeal = Appeal.last
        appeal_type = dup_appeal.docket_type,
        appeal_uuid = dup_appeal.uuid,
        created_at = Time.zone.now.utc,
        created_by_id = current_user.id,
        original_appeal_id = appeal.id,
        original_appeal_uuid = appeal.uuid,
        original_request_issue_ids = [request_issue.id, request_issue2.id, request_issue3.id],
        relationship_type = "split_appeal",
        split_other_reason = split_other_reason,
        split_reason = split_reason,
        split_request_issue_ids = [],
        updated_at = Time.zone.now.utc,
        updated_by_id = current_user.id,
        working_split_status = Constants.TASK_STATUSES.in_progress
        appeal_split_task = appeal.tasks.where(type: "SplitAppealTask").first
        dup_split_task = dup_appeal.tasks.where(type: "SplitAppealTask").first
        expect(SCT.split_other_reason).to eq("")
      end
    end

    context "with invalid parameters" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:invalid_params) do
        {
          appeal_id: -5,
          appeal_split_issues: { request_issue.id.to_s => true },
          split_reason: "Include a motion for CUE with respect to a prior Board decision",
          split_other_reason: ""
        }
      end

      it "doesn't create the new split appeal" do
        post :split_appeal, params: invalid_params
        expect Appeal.count == 0
        expect(response).to have_http_status 404
        expect(response.body).to eq("404 Not Found")
      end
    end

    context "with complete failure make sure SplitCorrelationTable does not create" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:invalid_params) do
        {
          appeal_id: "fail",
          appeal_split_issues: { request_issue.id.to_s => true },
          split_reason: "Include a motion for CUE with respect to a prior Board decision",
          split_other_reason: ""
        }
      end

      it "doesn't create the new split appeal and performs a active record rollback" do
        post :split_appeal, params: invalid_params
        expect(SplitCorrelationTable.last).to eq(nil)
      end
    end

    context "the appeal is split" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:root_task) { RootTask.find(create(:root_task).id) }
      let(:appeal) { create(:appeal, tasks: [root_task]) }
      let(:valid_params) do
        {
          appeal_id: appeal.id,
          appeal_split_issues: { request_issue.id => true },
          split_reason: "Include a motion for CUE with respect to a prior Board decision",
          split_other_reason: "",
          user_css_id: ssc_user.css_id
        }
      end
      it "maintains the same relations as the original appeal" do
        post :split_appeal, params: valid_params
        dup_appeal = Appeal.last
        expect(appeal.stream_docket_number).equal? dup_appeal.stream_docket_number
      end
    end

    context "with an appeal that has a full hearing day" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let!(:hearing_day) do
        create(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:video],
          regional_office: "RO18",
          scheduled_for: Time.zone.today + 1.week
        )
      end
      let(:root_task) { RootTask.find(create(:root_task).id) }
      let(:appeal) { create(:appeal, tasks: [root_task]) }
      let!(:hearing) do
        create(
          :hearing,
          appeal: appeal,
          hearing_day: hearing_day
        )
      end
      before do
        6.times do
          create(:hearing, hearing_day: hearing_day)
          create(:case_hearing, vdkey: hearing_day.id)
        end
      end
      let(:valid_params) do
        {
          appeal_id: appeal.id,
          appeal_split_issues: { request_issue.id.to_s => true },
          split_reason: "Include a motion for CUE with respect to a prior Board decision",
          split_other_reason: "",
          user_css_id: ssc_user.css_id
        }
      end
      it "creates the split appeal despite the hearing_day being full" do
        hearing_day.reload
        post :split_appeal, params: valid_params
        expect(appeal.stream_docket_number).to eq(Appeal.last.stream_docket_number)
        expect(response).to have_http_status :success
      end

      it "keeps the same hearing day as the original appeal" do
        hearing_day.reload
        original_appeal = Appeal.find(appeal.id)
        post :split_appeal, params: valid_params
        dup_appeal = Appeal.last
        expect(original_appeal.hearings[0]).equal? dup_appeal.hearings[0]
        expect(original_appeal.hearings[0].hearing_day.id).equal? dup_appeal.hearings[0].hearing_day.id
      end
    end
  end
end
