describe "Appeals API v1", type: :request do
  context "Appeal list" do
    before { FeatureToggle.enable!(:appeals_status) }

    let!(:resolved_appeal) do
      Generators::Appeal.create(
        vacols_record: {
          template: :remand_decided,
          type: "Original",
          status: "Complete",
          appellant_ssn: "111223333",
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
        vacols_record: {
          template: :ready_to_certify,
          appellant_ssn: "111223333",
          nod_date: Time.zone.today - 11.months,
          soc_date: Time.zone.today - 9.months,
          form9_date: Time.zone.today - 7.months,
          ssoc_dates: [
            Time.zone.today - 8.months,
            Time.zone.today - 4.months
          ],
          decision_date: nil,
          prior_decision_date: Time.zone.today - 12.months
        }
      )
    end

    let!(:another_veteran_appeal) do
      Generators::Appeal.create(
        vacols_record: {
          template: :remand_decided,
          appellant_ssn: "3332223333"
        }
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

    it "returns 422 if ssn is invalid" do
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

      json_prior_decision_date = json["data"].first["attributes"]["prior_decision_date"]
      expect(json_prior_decision_date).to eq((Time.zone.today - 12.months).to_formatted_s(:csv_date))
      expect(json["data"].first["attributes"]["active"]).to eq(true)

      expect(json["data"].last["attributes"]["type"]).to eq("original")
      expect(json["data"].last["attributes"]["active"]).to eq(false)

      # check the events on the last appeal are correct
      event_types = json["data"].last["attributes"]["events"].map { |e| e["type"] }
      expect(event_types).to eq(%w(nod soc form9 bva_remand))
    end
  end
end
