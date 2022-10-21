# frozen_string_literal: true

RSpec.describe SplitAppealController, type: :controller do

  describe "POST split_appeal" do
    let(:ssc_user) { create(:user, roles: '{Hearing Prep,Reader,SPLTAPPLLANNISTER}')}

    before do
      User.authenticate!(user: ssc_user)
      FeatureToggle.enable!(:split_appeal_workflow)
    end

    context "with valid parameters" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }

      # let(:request_issue_params, {request_issue.id => true})
      let(:valid_params) do
          {
            appeal_id: 1,
            appeal_split_issues: {request_issue.id => true},
            split_reason: "Include a motion for CUE with respect to a prior Board decision",
            split_other_reason: ""
          }
      end

      it "creates a new split appeal" do 
          post :split_appeal, params: valid_params
          expect(response).to have_http_status :success
          original_appeal = Appeal.first
          dup_appeal = Appeal.last
          expect(original_appeal.stream_docket_number).to eq(dup_appeal.stream_docket_number)
          expect(original_appeal.veteran_file_number).to eq(dup_appeal.veteran_file_number)
      end
    end

    context "with invalid parameters" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:invalid_params) do
          {
            appeal_id: "fail",
            appeal_split_issues: {request_issue.id.to_s => true},
            split_reason: "Include a motion for CUE with respect to a prior Board decision",
            split_other_reason: ""
          }
      end

      it "doesn't create the new split appeal" do
          post :split_appeal, params: invalid_params 
          expect Appeal.count == 0
          expect(response).to have_http_status 404
      end
    end

    context "the appeal is split" do
      let(:benefit_type1) { "compensation" }
      let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }
      let(:original_appeal) { create(:appeal) }
      let(:valid_params) do
        {
          appeal_id: original_appeal.id,
          appeal_split_issues: {request_issue.id.to_s => true},
          split_reason: "Include a motion for CUE with respect to a prior Board decision",
          split_other_reason: ""
        }
      end
      it "maintains the same relations as the original appeal" do
        post :split_appeal, params: valid_params
        dup_appeal = Appeal.last
        expect(original_appeal.stream_docket_number).equal? dup_appeal.stream_docket_number
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
      let(:appeal) { create(:appeal, request_issues: [request_issue] ) }
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
            appeal_split_issues: {request_issue.id.to_s => true},
            split_reason: "Include a motion for CUE with respect to a prior Board decision",
            split_other_reason: ""
          }
      end
      it "creates the split appeal despite the hearing_day being full" do
        hearing_day.reload
        appeal_count = Appeal.count
        post :split_appeal, params: valid_params
        expect(Appeal.count).to be(appeal_count + 1)
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