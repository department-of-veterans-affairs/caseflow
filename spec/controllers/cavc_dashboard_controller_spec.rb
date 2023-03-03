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
            ["100", "request_issue", 1]
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
            ["100", "request_issue", 1]
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
            ["100", "request_issue", 1]
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
    it "#index returns nil for cavc_dashboards if appeal_id doesn't match any remands" do
      appeal = create(:appeal)

      get :index, params: { format: :json, appeal_id: appeal.uuid }
      response_body = JSON.parse(response.body)

      expect(response_body.key?("cavc_dashboards")).to be true
      expect(response_body["cavc_dashboards"]).to be nil
    end

    it "#index creates new dashboard and returns index data from format.json" do
      Seeds::CavcDashboardData.new.seed!

      remand = CavcRemand.last
      appeal_uuid = Appeal.find(remand.remand_appeal_id).uuid

      get :index, params: { format: :json, appeal_id: appeal_uuid }
      response_body = JSON.parse(response.body)
      dashboard = CavcDashboard.find_by(cavc_remand: remand)

      expect(response_body.key?("cavc_dashboards")).to be true
      expect(response_body["cavc_dashboards"][0]["cavc_dashboard_dispositions"].count)
        .to eq CavcDashboardDisposition.where(cavc_dashboard: dashboard).count
    end
  end
end
