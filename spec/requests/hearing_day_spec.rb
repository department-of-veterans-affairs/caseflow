require "rails_helper"

RSpec.describe "Hearing Schedule", type: :request do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 0, 0, 0))
  end

  let!(:user) do
    User.authenticate!(roles: ["Build HearSched"])
  end

  describe "Create a schedule slot - VACOLS" do
    it "Create one schedule day" do
      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: DateTime.new(2018, 6, 7, 9, 0, 0, "+0"), room: "1" }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2018, 6, 7))
      expect(JSON.parse(response.body)["hearing"]["request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("1 (1W200A)")
    end
  end

  describe "Create a schedule slot - Caseflow" do
    it "Create one schedule day" do
      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: "7-Jun-2019", room: "1" }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 6, 7))
      expect(JSON.parse(response.body)["hearing"]["request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("1 (1W200A)")
    end
  end

  describe "Create a new hearing day (Add Hearing) - Caseflow" do
    let(:jan_hearing_days) do
      (1..6).each do |n|
        create(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:video],
                             scheduled_for: Date.new(2019, 4, 14), room: n.to_s)
      end
    end

    it "Create new adhoc hearing day and automatically assign a room" do
      jan_hearing_days

      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:video],
                                              scheduled_for: "14-Apr-2019", assign_room: true }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 4, 14))
      expect(JSON.parse(response.body)["hearing"]["request_type"]).to eq("Video")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("7 (1W434)")
    end

    it "Create new adhoc hearing day and do not assign a room (room should be nil in DB)" do
      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: "17-Jan-2019", assign_room: false }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 1, 17))
      expect(JSON.parse(response.body)["hearing"]["request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq(nil)
    end

    it "Create new adhoc Central Office hearing day and assign room 2" do
      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: "17-Jan-2019", assign_room: true }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 1, 17))
      expect(JSON.parse(response.body)["hearing"]["request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("2 (1W200B)")
    end

    let(:may_hearing_days) do
      (1..13).each do |n|
        create(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:video],
                             scheduled_for: Date.new(2019, 5, 14), room: n.to_s)
      end
    end

    it "Create new adhoc hearing day but no rooms available. Confirm error message received." do
      may_hearing_days

      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:video],
                                              scheduled_for: "14-May-2019", assign_room: true }
      expect(response).to have_http_status(404)
      expect(JSON.parse(response.body)["errors"][0]["title"]).to eq("No rooms available")
      expect(JSON.parse(response.body)["errors"][0]["detail"]).to eq("All rooms are taken for the date selected.")
    end

    let(:mar_hearing_days) do
      (1..13).each do |n|
        create(:hearing_day, scheduled_for: Date.new(2019, 3, 14), room: n.to_s)
      end
    end

    it "Create new adhoc hearing day on a full day. Room assignment not required, hence is empty string." do
      mar_hearing_days

      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: "14-Mar-2019", assign_room: false }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 3, 14))
      expect(JSON.parse(response.body)["hearing"]["request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq(nil)
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
        [{
          request_type: HearingDay::REQUEST_TYPES[:central], scheduled_for: "7-Jun-2017 09:00:00.000-4:00", room: "1"
        },
         { request_type: HearingDay::REQUEST_TYPES[:central], scheduled_for: "9-Jun-2017 13:00:00.000-4:00", room: "3",
           judge_id: 105 },
         { request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "15-Jun-2017 08:30:00.000-4:00",
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
    end
  end

  describe "Show a hearing day with its children hearings" do
    let!(:child_hearing) do
      create(:case_hearing,
             hearing_type: "V",
             hearing_date: DateTime.new(2018, 4, 2, 8, 30, 0, "+0"),
             folder_nr: create(:case).bfkey)
    end
    let!(:co_hearing) do
      create(:case_hearing,
             hearing_type: "C",
             hearing_date: DateTime.new(2018, 4, 2, 9, 0, 0, "+0"),
             folder_nr: create(:case).bfkey)
    end

    it "returns video children hearings", skip: "This test is flaky" do
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day/" + child_hearing.vdkey.to_s, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing_day"]["request_type"]).to eq("Video")
      expect(JSON.parse(response.body)["hearing_day"]["hearings"].count).to eq(1)
    end

    it "returns co children hearings" do
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day/" + co_hearing.hearing_pkseq.to_s, headers: headers
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearing_day"]["request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing_day"]["hearings"].count).to eq(1)
    end
  end

  describe "Get hearing schedule for a date range - Caseflow" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      HearingDay.create(
        [{ request_type: HearingDay::REQUEST_TYPES[:central], scheduled_for: "7-Jun-2019 09:00:00.000-4:00",
           room: "1", created_by: "ramiro", updated_by: "ramiro" },
         { request_type: HearingDay::REQUEST_TYPES[:central], scheduled_for: "9-Jun-2019 13:00:00.000-4:00",
           room: "3", judge_id: 105, created_by: "ramiro", updated_by: "ramiro" },
         { request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "15-Jun-2019 08:30:00.000-4:00",
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
    end
  end

  # Default dates test case not applicable until default date range reaches 4/1/2019
  describe "Get hearing schedule with default dates - VACOLS Only" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ request_type: HearingDay::REQUEST_TYPES[:central],
           scheduled_for: (Time.zone.today - 15.days).to_date, room: "1" },
         { request_type: HearingDay::REQUEST_TYPES[:central],
           scheduled_for: (Time.zone.today + 315.days).to_date, room: "3" }]
      )
      Generators::Vacols::TravelBoardSchedule.create(tbmem1: "111")
      Generators::Vacols::Staff.create(sattyid: "111")
    end

    it "Get hearings for default dates", skip: "Test is flakey" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", headers: headers
      expect(response).to have_http_status(:success)
      # We don't pull in VACOLS hearings later than 1/1
      expect(JSON.parse(response.body)["hearings"].size).to be(1)
    end
  end

  describe "Get hearing schedule for an RO - VACOLS" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::CaseHearing.create(
        [{ request_type: HearingDay::REQUEST_TYPES[:central], scheduled_for: "7-Jun-2017 09:00:00.000-4:00", room: "1",
           regional_office: "RO17" },
         { request_type: HearingDay::REQUEST_TYPES[:central], scheduled_for: "9-Jun-2017 09:00:00.000-4:00", room: "3",
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
    end
  end

  describe "Get hearing schedule for an RO - Caseflow" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      HearingDay.create(
        [{ request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "7-Jun-2019 09:00:00.000-4:00",
           room: "1", regional_office: "RO17", created_by: "ramiro", updated_by: "ramiro" },
         { request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "9-Jun-2019 09:00:00.000-4:00",
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
    end
  end

  describe "Get hearings with veterans" do
    let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::Staff.create(sattyid: "111")
      HearingDay.create(
        [{ request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "7-Mar-2019 09:00:00.000-4:00",
           room: "1", regional_office: "RO04", created_by: "ramiro", updated_by: "ramiro" },
         { request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "9-Mar-2019 09:00:00.000-4:00",
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

  describe "Get CO scheduled hearing with correct time.", skip: "This test can come back when we pull CO
      children records by ID instead of by date" do
    let!(:staff) { create(:staff, stafkey: "RO18", stc2: 2, stc3: 3, stc4: 4) }
    let(:vacols_case) do
      create(
        :case,
        folder: create(:folder, tinum: "docket-number"),
        bfregoff: "RO18",
        bfcurloc: "57"
      )
    end
    let(:appeal) do
      create(:legacy_appeal, :with_veteran, vacols_case: vacols_case)
    end
    let!(:hearing_day) do
      create(:hearing_day, hearing_type: "C", scheduled_for: Date.new(2019, 1, 7))
    end
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::Vacols::Staff.create(sattyid: "111")
      create(:case_hearing,
             hearing_type: "C",
             hearing_date: VacolsHelper.format_datetime_with_utc_timezone(Time.zone.local(2019, 0o1, 0o7, 9, 0, 0)),
             folder_nr: appeal.vacols_id,
             vdkey: hearing_day.id)
    end

    it "Get scheduled hearing for veteran. Check hearing time is in EST" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/schedule/assign/hearing_days", params: {}, headers: headers
      expect(response).to have_http_status(:success)
      hearing_days = JSON.parse(response.body)["hearing_days"]
      expect(hearing_days.size).to be(1)
      expected_hearing_date = VacolsHelper.normalize_vacols_datetime(hearing_days[0]["hearings"][0]["scheduled_for"])
      expect(expected_hearing_date).to eq(Time.zone.local(2019, 0o1, 0o7, 9, 0, 0))
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
