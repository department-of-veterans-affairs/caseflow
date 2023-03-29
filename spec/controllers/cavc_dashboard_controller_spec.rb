# frozen_string_literal: true

RSpec.describe CavcDashboardController, type: :controller do
  # add organization to this user once they are implemented
  let(:authorized_user) { create(:user) }
  let(:occteam_organization) { OccTeam.singleton }
  let(:oicteam_organization) { OaiTeam.singleton }
  before do
    User.authenticate!(user: authorized_user)
    occteam_organization.add_user(authorized_user)
    oicteam_organization.add_user(authorized_user)
  end

  context "for routes not specific to an appeal" do
    it "#cavc_decision_reasons returns all CavcDecisionReasons" do
      Seeds::CavcDecisionReasonData.new.seed!

      get :cavc_decision_reasons

      expect(response.status).to eq 200
      expect(JSON.parse(response.body).count).to eq CavcDecisionReason.count
    end

    it "#cavc_selection_bases returns all CavcSelectionBases in DB" do
      Seeds::CavcSelectionBasisData.new.seed!

      get :cavc_selection_bases

      expect(response.status).to eq 200
      expect(JSON.parse(response.body).count).to eq CavcSelectionBasis.count
    end

    context "#update_data" do
      it "updates dashboard details with data" do
        remand = create(:cavc_remand)
        dashboard = CavcDashboard.create!(cavc_remand: remand)
        update_params = {
          updatedData:
            {
              "id" => dashboard.id,
              "boardDecisionDateUpdate" => "2022-06-08",
              "boardDocketNumberUpdate" => "230207-2186",
              "cavcDecisionDateUpdate" => "2023-02-24",
              "cavcDocketNumberUpdate" => "12-2444",
              "jointMotionForRemandUpdate" => "true"
            }
        }
        patch :update_data, params: update_params
        expect(JSON.parse(@response.body)["successful"]).to eq true
      end
    end

    context "#save" do
      before do
        CavcDecisionReason.create(decision_reason: "Duty to notify", order: 1)
      end

      it "saves new issues and dispositions" do
        remand = create(:cavc_remand)
        dashboard = CavcDashboard.create!(cavc_remand: remand)
        save_params = {
          cavc_dashboards: [
            {
              id: dashboard.id,
              cavc_dashboard_issues: [
                {
                  "id" => "33-0",
                  "benefit_type" => "insurance",
                  "cavc_dashboard_id" => dashboard.id,
                  "issue_category" => "Contested Death Claim | Other"
                }
              ],
              cavc_dashboard_dispositions: [
                {
                  # "id" => nil,
                  "cavc_dashboard_id" => dashboard.id,
                  "cavc_dashboard_issue_id" => "33-0",
                  # "request_issue_id" => nil,
                  "disposition" => "Settled",
                  "cavc_dispositions_to_reasons" => []
                }
              ]
            }
          ],
          checked_boxes: [
            {
              issue_id: dashboard.remand_request_issues.first.id,
              issue_type: "request_issue",
              decision_reason_id: CavcDecisionReason.first.id
            }
          ]
        }

        post :save, params: save_params
        expect(JSON.parse(@response.body)["successful"]).to eq true
        expect(CavcDashboardIssue.count).to eq 1
        # 3 for source request issues, 1 for cavc dashboard issue
        expect(CavcDashboardDisposition.count).to eq 4
        # ID value should be set by DB if matching regex for #-#
        expect(dashboard.cavc_dashboard_issues.first.id).not_to eq "33-0"
      end

      it "deletes removed issues and their dispositions" do
        remand = create(:cavc_remand)
        dashboard = CavcDashboard.create!(cavc_remand: remand)

        save_params = {
          cavc_dashboards: [
            {
              id: dashboard.id,
              cavc_dashboard_issues: [
                {
                  "id" => "33-0",
                  "benefit_type" => "insurance",
                  "cavc_dashboard_id" => dashboard.id,
                  "issue_category" => "Contested Death Claim | Other"
                },
                {
                  "id" => "33-1",
                  "benefit_type" => "pension",
                  "cavc_dashboard_id" => dashboard.id,
                  "issue_category" => "Accrued Benefits"
                }
              ],
              cavc_dashboard_dispositions: [
                {
                  # "id" => nil,
                  "cavc_dashboard_id" => dashboard.id,
                  "cavc_dashboard_issue_id" => "33-0",
                  # "request_issue_id" => nil,
                  "disposition" => "Settled",
                  "cavc_dispositions_to_reasons" => []
                },
                {
                  # "id" => nil,
                  "cavc_dashboard_id" => dashboard.id,
                  "cavc_dashboard_issue_id" => "33-1",
                  # "request_issue_id" => nil,
                  "disposition" => "Settled",
                  "cavc_dispositions_to_reasons" => []
                }
              ]
            }
          ],
          checked_boxes: [
            {
              issue_id: dashboard.remand_request_issues.first.id,
              issue_type: "request_issue",
              decision_reason_id: CavcDecisionReason.first.id
            }
          ]
        }
        post :save, params: save_params
        dashboard.reload

        update_params = {
          cavc_dashboards: [
            {
              id: dashboard.id,
              cavc_dashboard_issues: [{
                "id" => CavcDashboardIssue.last.id,
                "benefit_type" => "pension",
                "cavc_dashboard_id" => 51,
                "issue_category" => "Accrued Benefits"
              }],
              cavc_dashboard_dispositions: [
                {
                  # "id" => nil,
                  "cavc_dashboard_id" => dashboard.id,
                  "cavc_dashboard_issue_id" => CavcDashboardIssue.last.id,
                  # "request_issue_id" => nil,
                  "disposition" => "Settled",
                  "cavc_dispositions_to_reasons" => []
                }
              ]
            }
          ],
          checked_boxes: [
            {
              issue_id: dashboard.remand_request_issues.first.id,
              issue_type: "request_issue",
              decision_reason_id: CavcDecisionReason.first.id
            }
          ]
        }
        post :save, params: update_params
        dashboard.reload

        expect(JSON.parse(@response.body)["successful"]).to eq true
        expect(dashboard.cavc_dashboard_issues.count).to eq 1
        expect(CavcDashboardIssue.count).to eq 1
        expect(CavcDashboardDisposition.count).to eq 4
      end
    end
  end

  context "for routes specific to an appeal" do
    it "#index redirects user if trying to access the dashboard for a legacy appeal" do
      vacols_formatted_id = "1234567"
      get :index, params: { appeal_id: vacols_formatted_id }

      # expecting redirect_to was not working, so check status and location which are set when redirecting
      expect(response.status).to eq 302
      expect(response.headers["Location"].include?("1234567")).to be true
      expect(response.headers["Location"].include?("cavc_dashboard")).to be false
    end

    it "#index returns nil for cavc_dashboards if appeal_id doesn't match any remands" do
      appeal = create(:appeal)

      get :index, params: { format: :json, appeal_id: appeal.uuid }
      response_body = JSON.parse(response.body)

      expect(response_body.key?("cavc_dashboards")).to be true
      expect(response_body["cavc_dashboards"]).to be nil
    end

    it "#index creates new dashboard and returns index data from format.json" do
      remand = create(:cavc_remand)
      appeal_uuid = remand.remand_appeal.uuid

      get :index, params: { format: :json, appeal_id: appeal_uuid }
      response_body = JSON.parse(response.body)
      dashboard = CavcDashboard.find_by(cavc_remand: remand)

      expect(response_body.key?("cavc_dashboards")).to be true
      expect(response_body["cavc_dashboards"][0]["cavc_dashboard_dispositions"].count)
        .to eq CavcDashboardDisposition.where(cavc_dashboard: dashboard).count
    end

    it "#index creates a new dashboard for a decision that doesn't create a remand appeal stream" do
      appeal = create(:appeal, :dispatched, :with_decision_issue)

      creation_params = {
        source_appeal_id: appeal.id,
        cavc_decision_type: Constants::CAVC_DECISION_TYPES["affirmed"],
        cavc_docket_number: "12-3456",
        cavc_judge_full_name: "Clerk",
        created_by_id: authorized_user.id,
        decision_date: 1.week.ago,
        decision_issue_ids: appeal.decision_issue_ids,
        instructions: "Seed remand for testing",
        represented_by_attorney: true,
        updated_by_id: authorized_user.id,
        remand_subtype: nil,
        judgement_date: 1.week.ago,
        mandate_date: 1.week.ago
      }
      cavc_remand = CavcRemand.create!(creation_params)

      get :index, params: { format: :json, appeal_id: cavc_remand.source_appeal.uuid }
      response_body = JSON.parse(response.body)
      expect(response_body.key?("cavc_dashboards")).to be true
      expect(response_body["cavc_dashboards"][0]["remand_request_issues"]&.count).to be 1
    end
  end
end
