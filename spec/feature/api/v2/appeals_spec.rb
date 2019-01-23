describe "Appeals API v2", type: :request do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  before do
    allow(AppealRepository).to receive(:latest_docket_month) { 11.months.ago.to_date.beginning_of_month }
    allow(AppealRepository).to receive(:regular_non_aod_docket_count) { 123_456 }
    allow(AppealRepository).to receive(:docket_counts_by_month) do
      (1.year.ago.to_date..Time.zone.today).map { |d| Date.new(d.year, d.month, 1) }.uniq.each_with_index.map do |d, i|
        {
          "year" => d.year,
          "month" => d.month,
          "cumsum_n" => i * 10_000 + 3456,
          "cumsum_ready_n" => i * 5000 + 3456
        }
      end
    end
  end

  context "Appeal list" do
    before do
      DocketSnapshot.create
    end

    let!(:original) do
      create(:legacy_appeal, vacols_case: create(
        :case,
        :type_original,
        :status_complete,
        :disposition_remanded,
        bfdrodec: Time.zone.today - 18.months,
        bfdnod: Time.zone.today - 12.months,
        bfdsoc: Time.zone.today - 9.months,
        bfd19: Time.zone.today - 8.months,
        bfssoc1: Time.zone.today - 7.months,
        bfddec: Time.zone.today - 5.months,
        remand_return_date: 2.days.ago,
        bfcorlid: "111223333S",
        bfkey: "1234567",
        case_issues: [create(
          :case_issue,
          :disposition_remanded,
          issdcls: Time.zone.today - 5.months,
          issprog: "02",
          isscode: "15",
          isslev1: "03",
          isslev2: "5252"
        )],
        case_hearings: [build(:case_hearing, :disposition_held, hearing_date: 6.months.ago)]
      ))
    end

    let!(:post_remand) do
      create(:legacy_appeal, vacols_case: create(
        :case,
        :assigned,
        :type_post_remand,
        :status_active,
        bfdrodec: Time.zone.today - 18.months,
        bfdnod: Time.zone.today - 12.months,
        bfdsoc: Time.zone.today - 9.months,
        bfd19: Time.zone.today - 8.months,
        bfssoc1: Time.zone.today - 7.months,
        bfssoc2: Time.zone.today - 4.months,
        bfdpdcn: Time.zone.today - 5.months,
        bfcorlid: "111223333S",
        bfkey: "7654321",
        case_issues: [create(:case_issue, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252")]
      ))
    end

    let!(:another_original) do
      create(:legacy_appeal, vacols_case: create(
        :case,
        :type_original,
        :status_advance,
        :aod,
        bfdrodec: Time.zone.today - 12.months,
        bfdnod: Time.zone.today - 6.months,
        bfdsoc: Time.zone.today - 5.months,
        bfcorlid: "111223333S",
        case_issues: [
          create(:case_issue, issprog: "02", isscode: "15", isslev1: "04", isslev2: "5301"),
          create(
            :case_issue,
            :disposition_granted_by_aoj,
            issprog: "02",
            isscode: "15",
            isslev1: "04",
            isslev2: "5302",
            issdcls: Time.zone.today - 5.days
          )
        ]
      ))
    end

    let!(:another_veteran_appeal) do
      create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "333222333S"))
    end

    let(:api_key) { ApiKey.create!(consumer_name: "Testington Roboterson") }

    let(:veteran_file_number) { "111223333" }
    let!(:veteran) { create(:veteran, file_number: veteran_file_number) }
    let(:receipt_date) { nil }
    let(:benefit_type) { "compensation" }
    let(:informal_conference) { nil }
    let(:same_office) { nil }
    let(:legacy_opt_in_approved) { false }
    let(:veteran_is_not_claimant) { false }
    let(:profile_date) { receipt_date - 1 }

    let!(:claim_review) do
      create(:higher_level_review,
             veteran_file_number: veteran_file_number,
             receipt_date: receipt_date,
             informal_conference: informal_conference,
             same_office: same_office,
             benefit_type: benefit_type,
             legacy_opt_in_approved: legacy_opt_in_approved,
             veteran_is_not_claimant: veteran_is_not_claimant)
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

      allow(ApiKey).to receive(:authorize).and_raise("Much random error")
      expect(Raven).to receive(:capture_exception)
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
      expect(response).to be_success

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

    it "returns list of hlrs for veteran with SSN" do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_file_number_by_ssn) do |_bgs|
        veteran_file_number
      end

      FeatureToggle.enable!(:api_appeal_status_v3)

      headers = {
        "ssn": veteran_file_number,
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", headers: headers

      json = JSON.parse(response.body)

      # test for the 200 status-code
      expect(response).to be_success
      # check to make sure the right amount of appeals are returned
      expect(json["data"].length).to eq(1)

      # check the attribtues on the hlr
      expect(json["data"].first["type"]).to eq("higherLevelReview")
      expect(json["data"].first["attributes"]["appealIds"].length).to eq(1)
      expect(json["data"].first["attributes"]["appealIds"].first).to include("HLR")
      expect(json["data"].first["attributes"]["updated"]).to eq("2015-01-01T07:00:00-05:00")
      expect(json["data"].first["attributes"]["type"]).to be_nil
      expect(json["data"].first["attributes"]["active"]).to eq(false)
      expect(json["data"].first["attributes"]["incompleteHistory"]).to eq(false)
      expect(json["data"].first["attributes"]["description"]).to be_nil
      expect(json["data"].first["attributes"]["aod"]).to be_nil
      expect(json["data"].first["attributes"]["location"]).to eq("aoj")
      expect(json["data"].first["attributes"]["alerts"]).to be_nil
      expect(json["data"].first["attributes"]["aoj"]).to be_nil
      expect(json["data"].first["attributes"]["programArea"]).to eq("compensation")
      expect(json["data"].first["attributes"]["docket"]).to be_nil
      expect(json["data"].first["attributes"]["status"]).to be_nil
      expect(json["data"].first["attributes"]["issues"].length).to eq(0)

      FeatureToggle.disable!(:api_appeal_status_v3)
    end
  end
end
