# frozen_string_literal: true

require "support/api_helpers"

describe "Appeals API v2", :all_dbs, type: :request do
  include ApiHelpers

  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  before do
    api_setup_appeal_repository_dockets
  end

  let(:api_key) { ApiKey.create!(consumer_name: "Testington Roboterson") }

  context "Legacy Appeal list" do
    before do
      DocketSnapshot.create
    end

    let(:vbms_id) { "111223333S" }

    let!(:original) { api_create_legacy_appeal_complete_with_hearings(vbms_id) }
    let!(:post_remand) { api_create_legacy_appeal_post_remand(vbms_id) }
    let!(:another_original) { api_create_legacy_appeal_advance(vbms_id) }

    let!(:another_veteran_appeal) do
      create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "333222333S"))
    end

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_file_number_by_ssn) do |_bgs, ssn|
        ssn
      end
    end

    it "returns 401 if API key not authorized" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=12312kdasdaskd"
      }

      get "/api/v2/appeals", headers: headers

      expect(response.code).to eq("401")

      expect(ApiView.count).to eq(0)
    end

    it "returns 422 if SSN is invalid" do
      headers = {
        "ssn": "11122333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", headers: headers

      expect(response.code).to eq("422")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Invalid SSN")

      expect(ApiView.count).to eq(0)
    end

    it "returns 404 if veteran with that SSN isn't found", skip: "I believe this just returns an empty array" do
      headers = {
        "ssn": "444444444",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", headers: headers

      expect(response.code).to eq("404")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Veteran not found")

      expect(ApiView.count).to eq(1)
    end

    it "records source if sent" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=#{api_key.key_string}",
        "source": "white house hotline"
      }

      get "/api/v2/appeals", headers: headers

      expect(ApiView.last.source).to eq("white house hotline")
    end

    it "caches response" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", headers: headers
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(2)

      # Make a new appeal and check that it isn't returned because of the cache
      create(:legacy_appeal, vacols_case: create(
        :case_with_decision,
        :status_remand,
        :disposition_remanded,
        bfcorlid: "111223333S",
        case_issues: [create(:case_issue, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252")]
      ))

      get "/api/v2/appeals", headers: headers
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(2)

      # tests that reload=true busts cache
      get "/api/v2/appeals?reload=true", headers: headers
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(3)

      expect(ApiView.count).to eq(3)
    end

    it "returns 500 on any other error" do
      headers = {
        "ssn": "444444444",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      random_error = StandardError.new("Much random error")

      allow(ApiKey).to receive(:authorize).and_raise(random_error)
      expect(Raven).to receive(:capture_exception).with(
        random_error, hash_including(extra: hash_including(vbms_id: "444444444S"))
      )
      expect(Raven).to receive(:last_event_id).and_return("a1b2c3")

      get "/api/v2/appeals", headers: headers

      expect(response.code).to eq("500")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Unknown error occured")
      expect(json["errors"].first["detail"]).to match("Much random error (Sentry event id: a1b2c3)")

      expect(ApiView.count).to eq(0)
    end

    it "returns 504 when BGS times out" do
      allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn).and_raise(Errno::ETIMEDOUT)

      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=#{api_key.key_string}"
      }
      get "/api/v2/appeals", headers: headers

      expect(response.code).to eq("504")
    end

    it "returns list of appeals for veteran with SSN" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", headers: headers

      json = JSON.parse(response.body)

      # test for the 200 status-code
      expect(response).to be_successful

      # check to make sure the right amount of appeals are returned
      expect(json["data"].length).to eq(2)

      # check the attribtues on the first appeal
      expect(json["data"].first["type"]).to eq("legacyAppeal")
      expect(json["data"].first["attributes"]["appealIds"].length).to eq(2)
      expect(json["data"].first["attributes"]["appealIds"]).to include("1234567")
      expect(json["data"].first["attributes"]["updated"]).to eq("2015-01-01T07:00:00-05:00")
      expect(json["data"].first["attributes"]["type"]).to eq("post_remand")
      expect(json["data"].first["attributes"]["active"]).to eq(true)
      expect(json["data"].first["attributes"]["incompleteHistory"]).to eq(false)
      expect(json["data"].first["attributes"]["description"]).to eq(
        "Service connection, limitation of thigh motion (flexion)"
      )
      expect(json["data"].first["attributes"]["aod"]).to eq(false)
      expect(json["data"].first["attributes"]["location"]).to eq("bva")
      expect(json["data"].first["attributes"]["alerts"]).to eq([{ "type" => "decision_soon", "details" => {} }])
      expect(json["data"].first["attributes"]["aoj"]).to eq("vba")
      expect(json["data"].first["attributes"]["programArea"]).to eq("compensation")
      expect(json["data"].first["attributes"]["docket"]["front"]).to eq(false)
      expect(json["data"].first["attributes"]["docket"]["total"]).to eq(123_456)
      expect(json["data"].first["attributes"]["docket"]["ahead"]).to eq(43_456)
      expect(json["data"].first["attributes"]["docket"]["ready"]).to eq(23_456)
      expect(json["data"].first["attributes"]["docket"]["month"]).to eq("2014-05-01")
      expect(json["data"].first["attributes"]["docket"]["docketMonth"]).to eq("2014-02-01")
      expect(json["data"].first["attributes"]["docket"]["eta"]).to be_nil

      # check the events on the first appeal are correct
      event_types = json["data"].first["attributes"]["events"].map { |e| e["type"] }
      expect(event_types).to eq(%w[claim_decision nod soc form9 ssoc hearing_held bva_decision ssoc remand_return])

      # check the status on the first appeal
      status = json["data"].first["attributes"]["status"]
      expect(status["type"]).to eq("decision_in_progress")
      expect(status["details"]["decisionTimeliness"]).to eq([1, 2])

      # check the first appeal's issue
      expect(json["data"].first["attributes"]["issues"])
        .to eq([
                 {
                   "description" => "Service connection, limitation of thigh motion (flexion)",
                   "diagnosticCode" => "5252",
                   "active" => true,
                   "lastAction" => "remand",
                   "date" => (Time.zone.today - 5.months).to_s
                 }
               ])

      # check the events on the last appeal are correct
      event_types = json["data"].last["attributes"]["events"].map { |e| e["type"] }
      expect(event_types).to eq(%w[claim_decision nod soc field_grant])

      # check for an alert on the last appeal
      expect(json["data"].last["attributes"]["alerts"].first["type"]).to eq("form9_needed")

      # check the status on the last appeal
      status = json["data"].last["attributes"]["status"]
      expect(status["type"]).to eq("pending_form9")

      # check the last appeal's issues
      expect(json["data"].last["attributes"]["issues"])
        .to eq([
                 {
                   "description" =>
                     "New and material evidence to reopen claim for service connection, shoulder or arm muscle injury",
                   "diagnosticCode" => "5301",
                   "active" => true,
                   "lastAction" => nil,
                   "date" => nil
                 },
                 {
                   "description" =>
                     "New and material evidence to reopen claim for service connection, shoulder or arm muscle injury",
                   "diagnosticCode" => "5302",
                   "active" => false,
                   "lastAction" => "field_grant",
                   "date" => (Time.zone.today - 5.days).to_s
                 }
               ])

      # check that the date for the last event was formatted correctly
      json_notification_date = json["data"].last["attributes"]["events"].first["date"]
      expect(json_notification_date).to eq((Time.zone.today - 12.months).to_formatted_s(:csv_date))

      # check the other attribtues on the last appeal
      expect(json["data"].last["type"]).to eq("legacyAppeal")
      expect(json["data"].last["attributes"]["updated"]).to eq("2015-01-01T07:00:00-05:00")
      expect(json["data"].last["attributes"]["active"]).to eq(true)
      expect(json["data"].last["attributes"]["incompleteHistory"]).to eq(false)
      expect(json["data"].last["attributes"]["aod"]).to eq(true)
      expect(json["data"].last["attributes"]["location"]).to eq("aoj")
      expect(json["data"].last["attributes"]["aoj"]).to eq("vba")
      expect(json["data"].last["attributes"]["programArea"]).to eq("compensation")

      # check stubbed attributes
      expect(json["data"].first["attributes"]["evidence"]).to eq([])

      expect(ApiView.count).to eq(1)
    end
  end

  context "All HLR, SC and Appeals" do
    before do
      Timecop.freeze(Time.utc(2018, 11, 28))
    end

    let(:veteran_file_number) { "111223333" }
    let(:receipt_date) { Date.new(2018, 9, 20) }
    let(:benefit_type) { "compensation" }
    let(:informal_conference) { nil }
    let(:same_office) { nil }
    let(:legacy_opt_in_approved) { false }
    let(:veteran_is_not_claimant) { false }
    let(:profile_date) { receipt_date - 1 }

    let!(:hlr) do
      create(:higher_level_review,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             informal_conference: informal_conference,
             same_office: same_office,
             benefit_type: benefit_type,
             legacy_opt_in_approved: legacy_opt_in_approved,
             veteran_is_not_claimant: veteran_is_not_claimant)
    end

    let!(:hlr_request_issue) do
      create(:request_issue,
             decision_review: hlr,
             benefit_type: benefit_type,
             contested_rating_issue_diagnostic_code: nil)
    end

    let!(:hlr_ep) do
      create(:end_product_establishment, :active, source: hlr)
    end

    let!(:supplemental_claim_review) do
      create(:supplemental_claim,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             benefit_type: "pension",
             legacy_opt_in_approved: legacy_opt_in_approved,
             veteran_is_not_claimant: veteran_is_not_claimant)
    end

    let!(:sc_request_issue) do
      create(:request_issue,
             decision_review: supplemental_claim_review,
             benefit_type: "pension",
             contested_rating_issue_diagnostic_code: "9999")
    end

    let!(:sc_ep) do
      create(:end_product_establishment,
             :cleared, source: supplemental_claim_review, last_synced_at: receipt_date + 100.days)
    end

    let!(:decision_issue) do
      create(:decision_issue,
             decision_review: supplemental_claim_review,
             disposition: "denied",
             end_product_last_action_date: receipt_date + 100.days)
    end

    let(:rating_promulgated_date) { receipt_date - 40.days }

    let(:request_issue1) do
      create(:request_issue, benefit_type: benefit_type,
                             contested_rating_issue_diagnostic_code: nil)
    end

    let(:request_issue2) do
      create(:request_issue, benefit_type: "education",
                             contested_rating_issue_diagnostic_code: nil)
    end

    let!(:appeal) do
      create(:appeal,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             request_issues: [request_issue1, request_issue2],
             docket_type: Constants.AMA_DOCKETS.evidence_submission)
    end

    let!(:task) { create(:task, :in_progress, type: RootTask.name, appeal: appeal) }

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_file_number_by_ssn) do |_bgs|
        veteran_file_number
      end

      allow_any_instance_of(RequestIssue).to receive(:decision_or_promulgation_date).and_return(rating_promulgated_date)
    end

    it "returns list of hlr, sc, appeal for veteran with SSN" do
      headers = {
        "ssn": veteran_file_number,
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", headers: headers

      json = JSON.parse(response.body)

      # test for the 200 status-code
      expect(response).to be_successful
      # check to make sure the right amount of appeals are returned
      expect(json["data"].length).to eq(3)

      # check the attributes on the hlr
      expect(json["data"].first["type"]).to eq("higherLevelReview")
      expect(json["data"].first["id"]).to include("HLR")
      expect(json["data"].first["attributes"]["appealIds"].length).to eq(1)
      expect(json["data"].first["attributes"]["appealIds"].first).to include("HLR")
      expect(json["data"].first["attributes"]["updated"]).to eq("2018-11-27T19:00:00-05:00")
      expect(json["data"].first["attributes"]["type"]).to be_nil
      expect(json["data"].first["attributes"]["active"]).to eq(true)
      expect(json["data"].first["attributes"]["incompleteHistory"]).to eq(false)
      expect(json["data"].first["attributes"]["description"]).to eq("1 compensation issue")
      expect(json["data"].first["attributes"]["aod"]).to be_nil
      expect(json["data"].first["attributes"]["location"]).to eq("aoj")
      expect(json["data"].first["attributes"]["alerts"].count).to eq(0)
      expect(json["data"].first["attributes"]["aoj"]).to eq("vba")
      expect(json["data"].first["attributes"]["programArea"]).to eq("compensation")
      expect(json["data"].first["attributes"]["docket"]).to be_nil
      expect(json["data"].first["attributes"]["status"]["type"]).to eq("hlr_received")

      expect(json["data"].first["attributes"]["issues"].length).to eq(1)
      issue = json["data"].first["attributes"]["issues"].first
      expect(issue["active"]).to eq(true)
      expect(issue["lastAction"]).to be_nil
      expect(issue["date"]).to be_nil
      expect(issue["diagnosticCode"]).to be_nil
      expect(issue["description"]).to eq("Compensation issue")

      event_type = json["data"].first["attributes"]["events"].first
      expect(event_type["type"]).to eq("hlr_request")
      expect(event_type["date"]).to eq(receipt_date.to_s)

      # check the attributes on the sc
      expect(json["data"][1]["type"]).to eq("supplementalClaim")
      expect(json["data"][1]["id"]).to include("SC")
      expect(json["data"][1]["attributes"]["appealIds"].length).to eq(1)
      expect(json["data"][1]["attributes"]["appealIds"].first).to include("SC")
      expect(json["data"][1]["attributes"]["updated"]).to eq("2018-11-27T19:00:00-05:00")
      expect(json["data"][1]["attributes"]["type"]).to be_nil
      expect(json["data"][1]["attributes"]["active"]).to eq(false)
      expect(json["data"][1]["attributes"]["incompleteHistory"]).to eq(false)
      expect(json["data"][1]["attributes"]["description"]).to eq("Dental or oral condition")
      expect(json["data"][1]["attributes"]["aod"]).to be_nil
      expect(json["data"][1]["attributes"]["location"]).to eq("aoj")
      expect(json["data"][1]["attributes"]["alerts"].count).to eq(1)
      expect(json["data"][1]["attributes"]["aoj"]).to eq("vba")
      expect(json["data"][1]["attributes"]["programArea"]).to eq("pension")
      expect(json["data"][1]["attributes"]["docket"]).to be_nil
      expect(json["data"][1]["attributes"]["status"]["type"]).to eq("sc_decision")

      status_details = json["data"][1]["attributes"]["status"]["details"]
      expect(status_details.length).to eq(1)
      expect(status_details["issues"].first["description"]).to eq("Dental or oral condition")
      expect(status_details["issues"].first["disposition"]).to eq("denied")

      expect(json["data"][1]["attributes"]["issues"].length).to eq(1)
      issue = json["data"][1]["attributes"]["issues"].first
      expect(issue["active"]).to eq(false)
      expect(issue["lastAction"]).to eq("denied")
      expect(issue["date"]).to eq((receipt_date + 100.days).to_s)
      expect(issue["diagnosticCode"]).to eq("9999")
      expect(issue["description"]).to eq("Dental or oral condition")

      request_event = json["data"][1]["attributes"]["events"].find { |e| e["type"] == "sc_request" }
      expect(request_event["date"]).to eq(receipt_date.to_s)

      decision_event = json["data"][1]["attributes"]["events"].find { |e| e["type"] == "sc_decision" }
      expect(decision_event["date"]).to eq((receipt_date + 100.days).to_s)

      # checkout the attributes on the appeal
      expect(json["data"][2]["type"]).to eq("appeal")
      expect(json["data"][2]["id"]).to include("A")
      expect(json["data"][2]["attributes"]["appealIds"].length).to eq(1)
      expect(json["data"][2]["attributes"]["appealIds"].first).to include("A")
      expect(json["data"][2]["attributes"]["updated"]).to eq("2018-11-27T19:00:00-05:00")
      expect(json["data"][2]["attributes"]["type"]).to eq(Constants.AMA_STREAM_TYPES.original.titleize)
      expect(json["data"][2]["attributes"]["active"]).to eq(true)
      expect(json["data"][2]["attributes"]["incompleteHistory"]).to eq(false)
      expect(json["data"][2]["attributes"]["description"]).to eq("2 issues")
      expect(json["data"][2]["attributes"]["aod"]).to eq(false)
      expect(json["data"][2]["attributes"]["location"]).to eq("bva")
      expect(json["data"][2]["attributes"]["alerts"].count).to eq(0)
      expect(json["data"][2]["attributes"]["aoj"]).to eq("vba")
      expect(json["data"][2]["attributes"]["programArea"]).to eq("multiple")
      expect(json["data"][2]["attributes"]["docket"]["type"]).to eq("evidenceSubmission")
      expect(json["data"][2]["attributes"]["docket"]["month"]).to eq(Date.new(2018, 9, 1).to_s)
      expect(json["data"][2]["attributes"]["docket"]["switchDueDate"]).to eq((rating_promulgated_date + 365.days).to_s)
      expect(json["data"][2]["attributes"]["docket"]["eligibleToSwitch"]).to eq(true)
      expect(json["data"][2]["attributes"]["status"]["type"]).to eq("on_docket")

      expect(json["data"][2]["attributes"]["issues"].length).to eq(2)
      issue = json["data"][2]["attributes"]["issues"].first
      expect(issue["active"]).to eq(true)
      expect(issue["lastAction"]).to be_nil
      expect(issue["date"]).to be_nil
      expect(issue["diagnosticCode"]).to be_nil

      event_type = json["data"][2]["attributes"]["events"].first
      expect(event_type["type"]).to eq("ama_nod")
      expect(event_type["date"]).to eq(receipt_date.to_s)
    end
  end

  context "HLR, SC and Appeal get filter out" do
    before do
      Timecop.freeze(Time.utc(2018, 11, 28))
    end

    let(:veteran_file_number) { "111223333" }
    let(:receipt_date) { Date.new(2018, 9, 20) }

    let!(:hlr) do
      create(:higher_level_review,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             benefit_type: "compensation")
    end

    let!(:supplemental_claim_review) do
      create(:supplemental_claim,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             benefit_type: "pension")
    end

    let!(:appeal) do
      create(:appeal,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             docket_type: Constants.AMA_DOCKETS.evidence_submission)
    end

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_file_number_by_ssn) do |_bgs|
        veteran_file_number
      end
    end

    it "will filter out claims and appeal because no request issues" do
      headers = {
        "ssn": veteran_file_number,
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", headers: headers

      json = JSON.parse(response.body)

      # test for the 200 status-code
      expect(response).to be_successful
      # check to make sure the right amount of appeals are returned
      expect(json["data"].length).to eq(0)
    end
  end

  context "Remanded SC filtered out" do
    before do
      Timecop.freeze(pre_ama_start_date)
    end

    let(:veteran_file_number) { "111223333" }
    let(:receipt_date) { Time.zone.today - 20.days }
    let(:benefit_type) { "compensation" }

    let(:hlr_ep_clr_date) { receipt_date + 30 }
    let!(:hlr_with_dta_error) do
      create(:higher_level_review,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date)
    end

    let!(:request_issue1) do
      create(:request_issue,
             decision_review: hlr_with_dta_error,
             benefit_type: benefit_type,
             contested_rating_issue_diagnostic_code: "9999")
    end

    let!(:hlr_epe) do
      create(:end_product_establishment, :cleared, source: hlr_with_dta_error)
    end

    let!(:hlr_decision_issue_with_dta_error) do
      create(:decision_issue,
             decision_review: hlr_with_dta_error,
             disposition: DecisionIssue::DTA_ERROR_PMR,
             rating_issue_reference_id: "rating1",
             benefit_type: benefit_type,
             end_product_last_action_date: hlr_ep_clr_date)
    end

    let!(:dta_sc) do
      create(:supplemental_claim,
             veteran_file_number: veteran_file_number,
             decision_review_remanded: hlr_with_dta_error)
    end

    let!(:request_issue2) do
      create(:request_issue,
             decision_review: dta_sc,
             benefit_type: benefit_type,
             contested_rating_issue_diagnostic_code: "9999")
    end

    let!(:dta_ep) do
      create(:end_product_establishment, :active, source: dta_sc)
    end

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_file_number_by_ssn) do |_bgs|
        veteran_file_number
      end
    end

    it "will have HLR and not remanded SC" do
      headers = {
        "ssn": veteran_file_number,
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", headers: headers

      json = JSON.parse(response.body)

      # test for the 200 status-code
      expect(response).to be_successful
      # check to make sure the right amount of appeals are returned
      expect(json["data"].length).to eq(1)
      expect(json["data"].first["type"]).to eq("higherLevelReview")
      expect(json["data"].first["id"]).to include("HLR")
      expect(json["data"].first["attributes"]["active"]).to eq(true)
    end
  end
end
