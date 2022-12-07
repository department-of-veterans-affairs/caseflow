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
      let(:request_issue2) { create(:request_issue, benefit_type: benefit_type2) }
      let(:benefit_type1) { "compensation" }
      let(:request_issue3) { create(:request_issue, benefit_type: benefit_type2) }
      let(:benefit_type2) { "pension" }
      let!(:appeal) do
        create(
          :appeal,
          tasks: [root_task],
          request_issues: [request_issue, request_issue2, request_issue3]
        )
      end

      let(:valid_params) do
        {
          appeal_id: appeal.id,
          appeal_split_issues: [request_issue.id.to_s, request_issue2.id.to_s],
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
        expect(dup_appeal.request_issues.count).to eq(2)
      end

      it "it sets the split request_issues on hold and removes them from the original appeal active" do
        post :split_appeal, params: valid_params
        expect(response.status).to eq 201
        dup_appeal = Appeal.last
        request_issue.reload
        request_issue2.reload
        expect(dup_appeal.request_issues.active.count).to eq(2)
        expect(appeal.request_issues.active.count).to eq(1)
        expect(request_issue.split_issue_status).to eq("on_hold")
        expect(request_issue2.split_issue_status).to eq("on_hold")
      end

      it "creates a split record for SplitCorrelationTable in DB and tasks" do
        post :split_appeal, params: valid_params
        dup_appeal = Appeal.last
        appeal_split_task = appeal.tasks.where(type: "SplitAppealTask").first
        dup_split_task = dup_appeal.tasks.where(type: "SplitAppealTask").first
        SCT = SplitCorrelationTable.last
        # creates a record in the split correlation table for each request issue split
        expect(SplitCorrelationTable.where(original_request_issue_id: request_issue.id).count).to eq(1)
        expect(SplitCorrelationTable.where(original_request_issue_id: request_issue2.id).count).to eq(1)

        # compare the split records to the original appeal/dup appeal
        split_entry1 = SplitCorrelationTable.find_by(original_request_issue_id: request_issue.id)
        split_entry2 = SplitCorrelationTable.find_by(original_request_issue_id: request_issue2.id)
        expect(split_entry1.appeal_id).to eq(dup_appeal.id)
        expect(split_entry2.appeal_id).to eq(dup_appeal.id)
        expect(split_entry1.original_request_issue_id).to eq(request_issue.id)
        expect(split_entry2.original_request_issue_id).to eq(request_issue2.id)
        expect(split_entry1.original_appeal_id).to eq(appeal.id)
        expect(split_entry2.original_appeal_id).to eq(appeal.id)

        # compare expect split task to be completed on appeal
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
      let(:appeal) do
        create(
          :appeal,
          tasks: [root_task],
          request_issues: [request_issue, request_issue2, request_issue3]
        )
      end
      let(:valid_params) do
        {
          appeal_id: appeal.id,
          appeal_split_issues: [request_issue.id.to_s],
          split_reason: "Other",
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
        sct_record = SplitCorrelationTable.find_by(original_appeal_id: appeal.id)
        dup_appeal = Appeal.last
        expect(SplitCorrelationTable.last.original_appeal_id).to eq(appeal.id)
        expect(sct_record.appeal_id).to eq(dup_appeal.id)
        expect(sct_record.split_reason).to eq("Other")
        expect(sct_record.split_other_reason).to eq("Some Other Reason")
        expect(sct_record.original_request_issue_id).to eq(request_issue.id)
        expect(sct_record.split_request_issue_id).to eq(dup_appeal.request_issues.first.id)
      end
    end

    context "with invalid parameters" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:invalid_params) do
        {
          appeal_id: -5,
          appeal_split_issues: [request_issue.id.to_s],
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
          appeal_split_issues: [request_issue.id.to_s],
          split_reason: "Include a motion for CUE with respect to a prior Board decision",
          split_other_reason: ""
        }
      end

      it "doesn't create the new split appeal and performs a active record rollback" do
        post :split_appeal, params: invalid_params
        expect(SplitCorrelationTable.last).to eq(nil)
      end
    end

    context "the issue has already been split (split_issue_status is 'on_hold')" do
      let(:root_task) { RootTask.find(create(:root_task).id) }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:request_issue2) { create(:request_issue, benefit_type: benefit_type2, split_issue_status: "on_hold") }
      let(:benefit_type1) { "compensation" }
      let(:request_issue3) { create(:request_issue, benefit_type: benefit_type2) }
      let(:benefit_type2) { "pension" }
      let!(:appeal) do
        create(
          :appeal,
          tasks: [root_task],
          request_issues: [request_issue, request_issue2, request_issue3]
        )
      end

      let(:valid_params) do
        {
          appeal_id: appeal.id,
          appeal_split_issues: [request_issue.id.to_s, request_issue2.id.to_s],
          split_reason: "Include a motion for CUE with respect to a prior Board decision",
          split_other_reason: "",
          user_css_id: ssc_user.css_id
        }
      end

      it "throws an error that the issue has already been split" do
        expect { post :split_appeal, params: valid_params }.to raise_error(Appeal::IssueAlreadyDuplicated)
        # the appeal is not duplicated
        expect(Appeal.where(stream_docket_number: appeal.stream_docket_number).count).to eq(1)
      end
    end

    context "the appeal is split" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:request_issue2) { create(:request_issue, benefit_type: benefit_type1) }
      let(:root_task) { RootTask.find(create(:root_task).id) }
      let(:appeal) { create(:appeal, tasks: [root_task], request_issues: [request_issue, request_issue2]) }
      let(:valid_params) do
        {
          appeal_id: appeal.id,
          appeal_split_issues: [request_issue.id.to_s],
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
      let(:request_issue2) { create(:request_issue, benefit_type: benefit_type1) }
      let!(:hearing_day) do
        create(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:video],
          regional_office: "RO18",
          scheduled_for: Time.zone.today + 1.week
        )
      end
      let(:root_task) { RootTask.find(create(:root_task).id) }
      let(:appeal) { create(:appeal, tasks: [root_task], request_issues: [request_issue, request_issue2]) }
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
          appeal_split_issues: [request_issue.id.to_s],
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
