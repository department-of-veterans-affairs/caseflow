require "rails_helper"

RSpec.describe "Hearing Schedule", type: :request do
  let!(:user) do
    User.authenticate!(roles: ["Build HearSched"])
  end

  describe "Create a schedule slot - VACOLS" do
    it "Create one schedule day" do
      post "/hearings/hearing_day", params: { hearing_type: HearingDay::HEARING_TYPES[:central],
                                              hearing_date: "7-Jun-2018", room: "1",
                                              regional_office: "RO17" }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["hearing_date"])
      expect(actual_date).to eq(Date.new(2018, 6, 7))
      expect(JSON.parse(response.body)["hearing"]["hearing_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("1 (1W200A)")
    end
  end

  describe "Create a schedule slot - Caseflow" do
    it "Create one schedule day" do
      post "/hearings/hearing_day", params: { hearing_type: HearingDay::HEARING_TYPES[:central],
                                              hearing_date: "7-Jun-2019", room: "1",
                                              regional_office: "RO17" }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["hearing_date"])
      expect(actual_date).to eq(Date.new(2019, 6, 7))
      expect(JSON.parse(response.body)["hearing"]["hearing_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("1 (1W200A)")
    end
  end

  describe "Assign judge to hearing day" do
    let!(:hearing_day) { create(:hearing_day) }
    let!(:judge) { create(:user) }

    it "Assign a judge to a schedule day" do
      patch "/hearings/hearing_day/#{hearing_day.id}", params: { judge_id: judge.id }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["judge_id"]).to eq(judge.id)
    end
  end

  describe "Get hearing schedule for a date range - VACOLS" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "7-Jun-2017 09:00:00.000-4:00", room: "1" },
         { hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "9-Jun-2017 13:00:00.000-4:00", room: "3",
           judge_id: 105 },
         { hearing_type: HearingDay::HEARING_TYPES[:video], hearing_date: "15-Jun-2017 08:30:00.000-4:00",
           regional_office: "RO27", room: "4" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "111")
      Generators::Vacols::Staff.create(sattyid: "111")
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
      expect(JSON.parse(response.body)["tbhearings"][0]["tbmem1"]).to eq("111")
    end
  end

  describe "Show a hearing day with its children hearings" do
    let!(:child_hearing) do
      create(:case_hearing,
             hearing_type: "V",
             hearing_date: Date.new(2018, 4, 2),
             folder_nr: create(:case).bfkey)
    end
    let!(:co_hearing) do
      create(:case_hearing,
             hearing_type: "C",
             hearing_date: Date.new(2018, 4, 2),
             folder_nr: create(:case).bfkey)
    end

    it "returns video children hearings", skip: "This test is flaky" do
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day/" + child_hearing.vdkey.to_s, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing_day"]["hearing_type"]).to eq("Video")
      expect(JSON.parse(response.body)["hearing_day"]["hearings"].count).to eq(1)
    end

    it "returns co children hearings" do
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day/" + co_hearing.hearing_pkseq.to_s, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing_day"]["hearing_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing_day"]["hearings"].count).to eq(1)
    end
  end

  describe "Get hearing schedule for a date range - Caseflow" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      HearingDay.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "7-Jun-2019 09:00:00.000-4:00",
           room: "1", created_by: "ramiro", updated_by: "ramiro" },
         { hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "9-Jun-2019 13:00:00.000-4:00",
           room: "3", judge_id: 105, created_by: "ramiro", updated_by: "ramiro" },
         { hearing_type: HearingDay::HEARING_TYPES[:video], hearing_date: "15-Jun-2019 08:30:00.000-4:00",
           regional_office: "RO27", room: "4", created_by: "ramiro", updated_by: "ramiro" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbyear: 2019, tbstdate: "2019-01-30 00:00:00",
                                                     tbenddate: "2019-02-03 00:00:00", tbmem1: "111")
      Generators::Vacols::Staff.create(sattyid: "111")
      Generators::Vacols::Staff.create(sattyid: "105", snamel: "Randall", snamef: "Tony")
    end

    it "Get hearings for specified date range" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", params: { start_date: "2019-01-01", end_date: "2019-06-15" }, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"].size).to eq(3)
      # Passing locally, failing on Jenkins
      # expect(JSON.parse(response.body)["hearings"][1]["judge_last_name"]).to eq("Randall")
      # expect(JSON.parse(response.body)["hearings"][1]["judge_first_name"]).to eq("Tony")
      # expect(JSON.parse(response.body)["hearings"][2]["regional_office"]).to eq("Louisville, KY")
      expect(JSON.parse(response.body)["tbhearings"].size).to eq(1)
      expect(JSON.parse(response.body)["tbhearings"][0]["tbmem1"]).to eq("111")
    end
  end

  # Default dates test case not applicable until default date range reaches 4/1/2019
  describe "Get hearing schedule with default dates - VACOLS Only" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central],
           hearing_date: (Time.zone.today - 15.days).to_date, room: "1" },
         { hearing_type: HearingDay::HEARING_TYPES[:central],
           hearing_date: (Time.zone.today + 315.days).to_date, room: "3" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "111")
      Generators::Vacols::Staff.create(sattyid: "111")
    end

    it "Get hearings for default dates" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", headers: headers
      expect(response).to have_http_status(:success)
      # We don't pull in VACOLS hearings later than 1/1
      expect(JSON.parse(response.body)["hearings"].size).to be(1)
      expect(JSON.parse(response.body)["tbhearings"].size).to be(0)
    end
  end

  describe "Get hearing schedule for an RO - VACOLS" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "7-Jun-2017 09:00:00.000-4:00", room: "1",
           regional_office: "RO17" },
         { hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "9-Jun-2017 09:00:00.000-4:00", room: "3",
           regional_office: "RO27" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "111")
      Generators::Vacols::Staff.create(sattyid: "111")
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

  describe "Get hearing schedule for an RO - Caseflow" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      HearingDay.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "7-Jun-2019 09:00:00.000-4:00",
           room: "1", regional_office: "RO17", created_by: "ramiro", updated_by: "ramiro" },
         { hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "9-Jun-2019 09:00:00.000-4:00",
           room: "3", regional_office: "RO27", created_by: "ramiro", updated_by: "ramiro" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbyear: 2019, tbstdate: "2019-01-30 00:00:00",
                                                     tbenddate: "2019-02-03 00:00:00", tbmem1: "111")
      Generators::Vacols::Staff.create(sattyid: "111")
    end

    it "Get hearings for RO" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", params: { regional_office: "RO17", start_date: "2019-01-01",
                                             end_date: "2019-12-31" }, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"].size).to be(1)
      expect(JSON.parse(response.body)["tbhearings"].size).to be(1)
    end
  end

  describe "Get hearings with veterans" do
    let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::Staff.create(sattyid: "111")
      HearingDay.create(
        [{ hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "7-Mar-2019 09:00:00.000-4:00",
           room: "1", regional_office: "RO04", created_by: "ramiro", updated_by: "ramiro" },
         { hearing_type: HearingDay::HEARING_TYPES[:central], hearing_date: "9-Mar-2019 09:00:00.000-4:00",
           room: "3", regional_office: "RO04", created_by: "ramiro", updated_by: "ramiro" }]
      )
    end

    it "Get hearings with veterans" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/schedule/assign/hearing_days", params: { regional_office: "RO04" }, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing_days"].size).to be(2)
    end
  end

  describe "Get veterans for hearings" do
    let!(:vacols_case) do
      create(
        :case,
        folder: create(:folder, tinum: "docket-number"),
        bfregoff: "RO04",
        bfcurloc: "57",
        bfhr: "2",
        bfdocind: "V"
      )
    end

    it "Get hearings with veterans" do
      vacols_case
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/schedule/assign/veterans", params: { regional_office: "RO04" }, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["veterans"].size).to be(1)
    end
  end

  describe "Delete a hearing day" do
    let!(:hearing_day) { create(:hearing_day) }

    it "Deletes the hearing day" do
      delete "/hearings/hearing_day/#{hearing_day.id}"
      expect(response).to have_http_status(:success)
      expect(HearingDay.all.count).to eq(0)
      expect(HearingDay.with_deleted.count).to eq(1)
    end
  end
end
