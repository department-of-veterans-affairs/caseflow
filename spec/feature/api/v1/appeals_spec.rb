describe "Appeals API v1", type: :request do
  context "Appeal list" do
    before { FeatureToggle.enable!(:appeals_status) }

    let!(:resolved_appeal) do
      Generators::Appeal.create(
        vbms_id: "111223333S",
        vacols_record: {
          template: :remand_decided,
          type: "Original",
          status: "Complete",
          nod_date: Time.zone.today - 12.months,
          soc_date: Time.zone.today - 9.months,
          form9_date: Time.zone.today - 7.months,
          disposition: "Remanded",
          decision_date: Time.zone.today - 5.months
        }
      )
    end

    let!(:current_appeal) do
      Generators::Appeal.create(
        vbms_id: "111223333S",
        vacols_record: {
          template: :ready_to_certify,
          nod_date: Time.zone.today - 11.months,
          soc_date: Time.zone.today - 9.months,
          form9_date: Time.zone.today - 7.months,
          ssoc_dates: [
            Time.zone.today - 8.months,
            Time.zone.today - 4.months
          ],
          decision_date: nil,
          prior_decision_date: Time.zone.today - 12.months,
          hearing_request_type: :travel_board,
          video_hearing_requested: true
        }
      )
    end

    let!(:another_veteran_appeal) do
      Generators::Appeal.create(vbms_id: "333222333S")
    end

    let!(:held_hearing) do
      Generators::Hearing.create(
        appeal: resolved_appeal,
        date: 6.months.ago,
        disposition: :held
      )
    end

    let!(:scheduled_hearing) do
      Generators::Hearing.create(
        appeal: current_appeal,
        date: 1.month.from_now,
        type: :travel_board
      )
    end

    let(:api_key) { ApiKey.create!(consumer_name: "Testington Roboterson") }

    it "returns 401 if API key not authorized" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=12312kdasdaskd"
      }

      get "/api/v1/appeals", nil, headers

      expect(response.code).to eq("401")
    end

    it "returns 422 if SSN is invalid" do
      headers = {
        "ssn": "11122333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v1/appeals", nil, headers

      expect(response.code).to eq("422")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Invalid SSN")
    end

    it "returns 404 if veteran with that SSN isn't found" do
      headers = {
        "ssn": "444444444",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v1/appeals", nil, headers

      expect(response.code).to eq("404")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Veteran not found")
    end

    it "caches response" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v1/appeals", nil, headers
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(2)

      # Make a new appeal and check that it isn't returned because of the cache
      Generators::Appeal.create(
        vbms_id: "111223333S",
        vacols_record: { template: :remand_decided }
      )

      get "/api/v1/appeals", nil, headers
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(2)

      # tests that reload=true busts cache
      get "/api/v1/appeals?reload=true", nil, headers
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(3)
    end

    it "returns 500 on any other error" do
      headers = {
        "ssn": "444444444",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      allow(ApiKey).to receive(:authorize).and_raise("Much random error")
      expect(Raven).to receive(:capture_exception)
      expect(Raven).to receive(:last_event_id).and_return("a1b2c3")

      get "/api/v1/appeals", nil, headers

      expect(response.code).to eq("500")

      json = JSON.parse(response.body)
      expect(json["errors"].length).to eq(1)
      expect(json["errors"].first["title"]).to eq("Unknown error occured")
      expect(json["errors"].first["detail"]).to match("Much random error (Sentry event id: a1b2c3)")
    end

    it "returns list of appeals for veteran with SSN" do
      headers = {
        "ssn": "111223333",
        "Authorization": "Token token=#{api_key.key_string}"
      }

      get "/api/v1/appeals", nil, headers

      json = JSON.parse(response.body)

      # test for the 200 status-code
      expect(response).to be_success

      # check to make sure the right amount of appeals are returned
      expect(json["data"].length).to eq(2)

      # check the events on the first appeal are correct
      event_types = json["data"].first["attributes"]["events"].map { |e| e["type"] }
      expect(event_types).to eq(%w(nod soc ssoc form9 ssoc))

      # check that the date for the first event was formatted correctly
      json_nod_date = json["data"].first["attributes"]["events"].first["date"]
      expect(json_nod_date).to eq((Time.zone.today - 11.months).to_formatted_s(:csv_date))

      # check for the hearing in the first appeal
      scheduled_hearings = json["data"].first["relationships"]["scheduled_hearings"]["data"]
      expect(scheduled_hearings.length).to eq(1)
      expect(scheduled_hearings.first["id"]).to eq(scheduled_hearing.id.to_s)

      # check that the scheduled hearing data is included
      expect(json["included"].first["id"]).to eq(scheduled_hearing.id.to_s)
      expect(json["included"].first["type"]).to eq("hearings")
      expect(json["included"].first["attributes"]["type"]).to eq("travel_board")
      scheduled_date = (Time.zone.today + 1.month).to_formatted_s(:csv_date)
      expect(json["included"].first["attributes"]["date"]).to eq(scheduled_date)

      # check the other attribtues on the first appeal
      json_prior_decision_date = json["data"].first["attributes"]["prior_decision_date"]
      expect(json_prior_decision_date).to eq((Time.zone.today - 12.months).to_formatted_s(:csv_date))
      expect(json["data"].first["attributes"]["active"]).to eq(true)
      expect(json["data"].first["attributes"]["requested_hearing_type"]).to eq("video")

      # check the attribtues on the last appeal
      expect(json["data"].last["attributes"]["type"]).to eq("original")
      expect(json["data"].last["attributes"]["active"]).to eq(false)

      # check the events on the last appeal are correct
      event_types = json["data"].last["attributes"]["events"].map { |e| e["type"] }
      expect(event_types).to eq(%w(nod soc form9 hearing_held bva_remand))
    end
  end
end
