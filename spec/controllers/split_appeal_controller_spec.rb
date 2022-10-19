# frozen_string_literal: true
RSpec.describe SplitAppealController, type: :controller do
    describe "POST split_appeal" do
      let(:ssc_user) { create(:user, roles: '{Hearing Prep,Reader,SPLTAPPLLANNISTER}')}

      before do
        User.authenticate!(user: ssc_user)
      end

      context "with valid parameters" do
        let(:benefit_type1) { "compensation" }
        let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }

        let(:valid_params) do
            {
                appeal_id: 1,
                appeal_split_issues: [request_issue.id],
                split_reason: "Include a motion for CUE with respect to a prior Board decision",
                split_other_reason: ""
            }
        end

        it "creates a new split appeal" do 
            post :split_appeal, params: valid_params
            expect(Appeal.count).to be(+1)
            expect(response).to have_http_status :success
        end
      end

      context "with invalid parameters" do
        let(:benefit_type1) { "compensation" }
        let(:request_issue) { create(:request_issue, benefit_type: benefit_type1) }

        let(:invalid_params) do
            {
                appeal_id: "fail",
                appeal_split_issues: [request_issue.id],
                split_reason: "Include a motion for CUE with respect to a prior Board decision",
                split_other_reason: ""
            }
        end

        it "doesn't create the new split appeal" do
            post :split_appeal, params: invalid_params 
            expect Appeal.count == 0
            expect(response).to have_http_status :success
        end
      end

    end
end