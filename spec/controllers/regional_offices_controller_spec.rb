# frozen_string_literal: true

RSpec.describe RegionalOfficesController, :all_dbs, type: :controller do
  let!(:user) { User.authenticate! }

  context "index" do
    it "returns all regional offices that hold hearings" do
      get :index, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["regional_offices"].size).to eq 56
    end
  end

  context "where a hearing day has an open slot" do
    let!(:child_hearing) do
      create(:case_hearing,
             hearing_type: HearingDay::REQUEST_TYPES[:video],
             hearing_date: Time.zone.today + 20,
             folder_nr: create(:case).bfkey)
    end

    let!(:co_hearing) do
      create(:case_hearing,
             hearing_type: HearingDay::REQUEST_TYPES[:central],
             hearing_date: Time.zone.today + 20,
             folder_nr: create(:case).bfkey)
    end

    it "returns all central hearing dates" do
      get :hearing_dates, params: { regional_office: HearingDay::REQUEST_TYPES[:central] }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["hearing_days"].size).to eq 1
    end
  end
end
