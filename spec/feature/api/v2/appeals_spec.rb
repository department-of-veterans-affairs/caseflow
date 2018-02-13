describe "Appeals API v2", type: :request do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context "Appeal list" do
    before do
      FeatureToggle.enable!(:appeals_status)
      DocketSnapshot.create
      post_remand.aod = false
    end

    let!(:original) do
      Generators::Appeal.create(
        vbms_id: "111223333S",
        vacols_id: "1234567",
        vacols_record: {
          template: :remand_decided,
          type: "Original",
          status: "Complete",
          notification_date: Time.zone.today - 18.months,
          nod_date: Time.zone.today - 12.months,
          soc_date: Time.zone.today - 9.months,
          form9_date: Time.zone.today - 8.months,
          ssoc_dates: [Time.zone.today - 7.months],
          disposition: "Remanded",
          decision_date: Time.zone.today - 5.months
        },
        issues: [
          Generators::Issue.build(
            disposition: :remanded,
            close_date: Time.zone.today - 5.months
          )
        ]
      )
    end

    let!(:post_remand) do
      Generators::Appeal.create(
        vbms_id: "111223333S",
        vacols_id: "7654321",
        vacols_record: {
          template: :ready_to_certify,
          type: "Post Remand",
          status: "Active",
          notification_date: Time.zone.today - 18.months,
          nod_date: Time.zone.today - 12.months,
          soc_date: Time.zone.today - 9.months,
          form9_date: Time.zone.today - 8.months,
          ssoc_dates: [
            Time.zone.today - 7.months,
            Time.zone.today - 4.months
          ],
          prior_decision_date: Time.zone.today - 5.months,
          disposition: nil,
          decision_date: nil
        },
        issues: [
          Generators::Issue.build(
            disposition: nil,
            close_date: nil
          )
        ]
      )
    end

    let!(:another_original) do
      Generators::Appeal.create(
        vbms_id: "111223333S",
        vacols_record: {
          template: :ready_to_certify,
          type: "Original",
          status: "Advance",
          notification_date: Time.zone.today - 12.months,
          nod_date: Time.zone.today - 6.months,
          soc_date: Time.zone.today - 5.days,
          form9_date: nil,
          disposition: nil,
          decision_date: nil
        },
        issues: [
          Generators::Issue.build(
            codes: %w[02 15 04 5301],
            labels: ["Compensation", "Service connection", "New and material", "Muscle injury, Group I"],
            disposition: nil,
            close_date: nil
          ),
          Generators::Issue.build(
            codes: %w[02 15 04 5302],
            labels: ["Compensation", "Service connection", "New and material", "Muscle injury, Group II"],
            disposition: :advance_allowed_in_field,
            close_date: Time.zone.today - 5.days
          )
        ]
      )
    end

    let!(:another_veteran_appeal) do
      Generators::Appeal.create(vbms_id: "333222333S")
    end

    let!(:held_hearing) do
      Generators::Hearing.create(
        appeal: original,
        date: 6.months.ago,
        disposition: :held
      )
    end

    let(:api_key) { ApiKey.create!(consumer_name: "Testington Roboterson") }

    it "returns 401 if API key not authorized" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=12312kdasdaskd"
      }

      get "/api/v2/appeals", nil, headers

      expect(response.code).to eq("401")

      expect(ApiView.count).to eq(0)
    end

    it "returns 422 if SSN is invalid" do
      headers = {
        "ssn": "11122333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", nil, headers

      expect(response.code).to eq("422")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Invalid SSN")

      expect(ApiView.count).to eq(0)
    end

    it "returns 404 if veteran with that SSN isn't found" do
      headers = {
        "ssn": "444444444",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", nil, headers

      expect(response.code).to eq("404")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Veteran not found")

      expect(ApiView.count).to eq(1)
    end

    it "caches response" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", nil, headers
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(2)

      # Make a new appeal and check that it isn't returned because of the cache
      Generators::Appeal.create(
        vbms_id: "111223333S",
        vacols_record: { template: :remand_decided }
      )

      get "/api/v2/appeals", nil, headers
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(2)

      # tests that reload=true busts cache
      get "/api/v2/appeals?reload=true", nil, headers
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

      get "/api/v2/appeals", nil, headers

      expect(response.code).to eq("500")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Unknown error occured")
      expect(json["errors"].first["detail"]).to match("Much random error (Sentry event id: a1b2c3)")

      expect(ApiView.count).to eq(0)
    end

    it "returns list of appeals for veteran with SSN" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v2/appeals", nil, headers

      json = JSON.parse(response.body)

      # test for the 200 status-code
      expect(response).to be_success

      # check to make sure the right amount of appeals are returned
      expect(json["data"].length).to eq(2)

      # check the attribtues on the first appeal
      expect(json["data"].first["attributes"]["appealIds"].length).to eq(2)
      expect(json["data"].first["attributes"]["appealIds"]).to include("1234567")
      expect(json["data"].first["attributes"]["updated"]).to eq("2015-01-01T07:00:00-05:00")
      expect(json["data"].first["attributes"]["type"]).to eq("post_remand")
      expect(json["data"].first["attributes"]["active"]).to eq(true)
      expect(json["data"].first["attributes"]["incompleteHistory"]).to eq(false)
      expect(json["data"].first["attributes"]["description"]).to eq("Service connection, limitation of thigh motion")
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
      expect(status["details"]["test"]).to eq("Hello World")

      # check the first appeal's issue
      expect(json["data"].first["attributes"]["issues"])
        .to eq([
                 {
                   "description" => "Service connection, limitation of thigh motion",
                   "diagnosticCode" => "5252",
                   "active" => true,
                   "lastAction" => "remand",
                   "date" => (Time.zone.today - 5.months).to_s
                 }
               ])

      # check the events on the last appeal are correct
      event_types = json["data"].last["attributes"]["events"].map { |e| e["type"] }
      expect(event_types).to eq(%w[claim_decision nod soc])

      # check for an alert on the last appeal
      expect(json["data"].last["attributes"]["alerts"].first["type"]).to eq("form9_needed")

      # check the status on the last appeal
      status = json["data"].last["attributes"]["status"]
      expect(status["type"]).to eq("pending_form9")

      # check the last appeal's issues
      expect(json["data"].last["attributes"]["issues"])
        .to eq([
                 {
                   "description" => "New and material evidence for service connection, shoulder or arm muscle injury",
                   "diagnosticCode" => "5301",
                   "active" => true,
                   "lastAction" => nil,
                   "date" => nil
                 },
                 {
                   "description" => "New and material evidence for service connection, shoulder or arm muscle injury",
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
end
