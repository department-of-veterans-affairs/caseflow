require "rails_helper"

RSpec.describe "Hearing Schedule", type: :request do
  let!(:user) do
    User.authenticate!(roles: ["Build HearSched"])
  end

  describe "Create a schedule slot" do
    it "Create one schedule" do
      post "/hearings/hearing_day", params: { hearing_type: HearingDay::HEARING_TYPES[:central],
                                              hearing_date: "7-Jun-2018 05:00:00.000-4:00", room_info: "1",
                                              regional_office: "RO17" }
      expect(response).to have_http_status(:success)
      actual_date = Time.parse(JSON.parse(response.body)["hearing"]["hearing_date"]).in_time_zone("UTC")
      expect(actual_date).to eq(Date.new(2018, 6, 7).in_time_zone("UTC"))
      actual_time = Date.parse(JSON.parse(response.body)["hearing"]["hearing_date"]).strftime('%H:%M:%S')
      expect(actual_time).to eq("00:00:00")
      expect(JSON.parse(response.body)["hearing"]["hearing_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room_info"]).to eq("1 (1W200A)")
    end
  end

  describe "Assign judge to hearing" do
    let!(:hearing) do
      RequestStore[:current_user] = user
      Generators::Vacols::Staff.create
      Generators::Vacols::CaseHearing.create(hearing_type: HearingDay::HEARING_TYPES[:central],
                                             hearing_date: "11-Jun-2017", room: "3")
    end

    it "Assign a judge to a schedule day" do
      put "/hearings/#{hearing.hearing_pkseq + 1}/hearing_day", params: { judge_id: "105" }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing"]["judge_id"]).to eq("105")
    end
  end

  describe "Modify RO in Travel Board Hearing" do
    let!(:hearing) do
      RequestStore[:current_user] = user
      Generators::Vacols::Staff.create
      Generators::Vacols::TravelBoardSchedule.create({})
    end

    it "Update RO in master TB schedule" do
      hearing
      put "/hearings/#{hearing.tbyear}-#{hearing.tbtrip}-#{hearing.tbleg}/hearing_day",
          params: { hearing_type: HearingDay::HEARING_TYPES[:travel], regional_office: "RO27" }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing"]["tbro"]).to eq("RO27")
    end
  end

  describe "Get hearing schedule for a date range" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "7-Jun-2017", room: "1" },
         { hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "9-Jun-2017", room: "3", judge_id: 105 },
         { hearing_type: HearingDay::HEARING_TYPES[:video], hearing_date: "15-Jun-2017",
           regional_office: "RO27", room: "3" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "955")
      Generators::Vacols::Staff.create(sattyid: "955")
    end

    it "Get hearings for specified date range" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", params: { start_date: "2017-01-01", end_date: "2017-06-15" }, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"].size).to eq(3)
      expect(JSON.parse(response.body)["hearings"][2]["regional_office"]).to eq("Louisville, KY")
      expect(JSON.parse(response.body)["tbhearings"].size).to eq(1)
    end
  end

  describe "Get hearing schedule with default dates" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central],
           hearing_date: (Time.zone.today.beginning_of_day - 15.days).to_date, room: "1" },
         { hearing_type: HearingDay::HEARING_TYPES[:central],
           hearing_date: (Time.zone.today.beginning_of_day + 315.days).to_date, room: "3" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "955")
      Generators::Vacols::Staff.create(sattyid: "955")
    end

    it "Get hearings for default dates" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"].size).to be(2)
      expect(JSON.parse(response.body)["tbhearings"].size).to be(0)
    end
  end

  describe "Get hearing schedule for an RO" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "7-Jun-2017", room: "1",
           regional_office: "RO17" },
         { hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "9-Jun-2017", room: "3",
           regional_office: "RO27" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "955")
      Generators::Vacols::Staff.create(sattyid: "955")
    end

    it "Get hearings for RO" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", params: { regional_office: "RO17", start_date: "2017-01-01",
                                             end_date: "2017-12-31" }, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"].size).to be(1)
      expect(JSON.parse(response.body)["tbhearings"].size).to be(1)
    end
  end
end
