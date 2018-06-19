require "rails_helper"

RSpec.describe "Hearing Schedule", type: :request do
  let!(:user) do
    User.authenticate!(roles: ["Hearing Schedule", "Reader"])
  end

  describe "Create a schedule slot" do
    it "Create one schedule" do
      post "/hearings/hearing_day", params: { hearing_type: HearingDay::HEARING_TYPES[:central_office],
                                              hearing_date: "7-Jun-2018", room: "1" }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing"]["data"]["attributes"]["hearing_type"]).to eq("C")
      expect(JSON.parse(response.body)["hearing"]["data"]["attributes"]["room"]).to eq("1")
    end
  end

  describe "Assign judge to hearing" do
    let!(:hearing) do
      RequestStore[:current_user] = user
      Generators::Vacols::Staff.create
      Generators::Vacols::CaseHearing.create(hearing_type: HearingDay::HEARING_TYPES[:central_office],
                                             hearing_date: "11-Jun-2017", room: "3")
    end

    it "Assign a judge to a schedule day" do
      put "/hearings/#{hearing.hearing_pkseq + 1}/hearing_day", params: { board_member: "105" }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing"]["data"]["attributes"]["board_member"]).to eq("105")
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
          params: { hearing_type: HearingDay::HEARING_TYPES[:travel], tbro: "RO27" }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing"]["data"]["attributes"]["tbro"]).to eq("RO27")
    end
  end

  describe "Get hearing schedule for a date range" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central_office], hearing_date: "7-Jun-2017", room: "1" },
         { hearing_type: HearingDay::HEARING_TYPES[:central_office], hearing_date: "9-Jun-2017", room: "3" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "955")
      Generators::Vacols::Staff.create(sattyid: "955")
    end

    it "Get hearings for specified date range" do
      hearings
      headers = {
        "ACCEPT" => "application/json",     # This is what Rails 4 accepts
        "HTTP_ACCEPT" => "application/json" # This is what Rails 3 accepts
      }
      get "/hearings/hearing_day", params: { start_date: "2017-01-01", end_date: "2017-12-31" }, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"]["data"].size).to be(2)
      expect(JSON.parse(response.body)["tbhearings"]["data"].size).to be(1)
    end
  end

  describe "Get hearing schedule with default dates" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central_office], hearing_date: "13-July-2017", room: "1" },
         { hearing_type: HearingDay::HEARING_TYPES[:central_office], hearing_date: "9-Jun-2018", room: "3" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "955")
      Generators::Vacols::Staff.create(sattyid: "955")
    end

    it "Get hearings for default dates" do
      hearings
      headers = {
        "ACCEPT" => "application/json",     # This is what Rails 4 accepts
        "HTTP_ACCEPT" => "application/json" # This is what Rails 3 accepts
      }
      get "/hearings/hearing_day", headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"]["data"].size).to be(2)
      expect(JSON.parse(response.body)["tbhearings"]["data"].size).to be(0)
    end
  end

  describe "Get hearing schedule for an RO" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central_office], hearing_date: "7-Jun-2017", room: "1",
         representative: "RO17"},
         { hearing_type: HearingDay::HEARING_TYPES[:central_office], hearing_date: "9-Jun-2017", room: "3",
         representative: "RO27"}]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "955")
      Generators::Vacols::Staff.create(sattyid: "955")
    end

    it "Get hearings for RO" do
      hearings
      headers = {
        "ACCEPT" => "application/json",     # This is what Rails 4 accepts
        "HTTP_ACCEPT" => "application/json" # This is what Rails 3 accepts
      }
      get "/hearings/hearing_day", params: { regional_office: "RO17", start_date: "2017-01-01", end_date: "2017-12-31" },
          headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"]["data"].size).to be(1)
      expect(JSON.parse(response.body)["tbhearings"]["data"].size).to be(1)
    end
  end
end
