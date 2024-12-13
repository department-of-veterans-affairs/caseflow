# frozen_string_literal: true

RSpec.describe "Hearing Day", :all_dbs, type: :request do
  URL_HOST = "example.va.gov"
  URL_PATH = "/sample"
  PIN_KEY = "mysecretkey"

  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 0, 0, 0))
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  let!(:user) do
    User.authenticate!(roles: ["Build HearSched"])
  end

  describe "Create a hearing day" do
    it "Creates one hearing day" do
      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: "7-Jun-2019", room: "1" }
      expect(response).to have_http_status(:success)
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 6, 7))
      expect(JSON.parse(response.body)["hearing"]["readable_request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("1 (1W200A)")
    end
  end

  describe "Create a new hearing day (Add Hearing)" do
    let(:jan_hearing_days) do
      (1..3).each do |n|
        create(
          :hearing_day,
          regional_office: "RO10",
          request_type: HearingDay::REQUEST_TYPES[:video],
          scheduled_for: Date.new(2019, 4, 14),
          room: n.to_s
        )
      end
      (1..3).each do |n|
        create(
          :hearing_day,
          regional_office: "RO10",
          request_type: HearingDay::REQUEST_TYPES[:travel],
          scheduled_for: Date.new(2019, 4, 14),
          room: (n + 3).to_s
        )
      end
    end

    it "Create new adhoc hearing day and automatically assign a room" do
      jan_hearing_days

      post "/hearings/hearing_day", params: { regional_office: "RO10",
                                              request_type: HearingDay::REQUEST_TYPES[:video],
                                              scheduled_for: "14-Apr-2019", assign_room: true }
      expect(response).to be_successful
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 4, 14))
      expect(JSON.parse(response.body)["hearing"]["readable_request_type"]).to eq("Video")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("7 (1W434)")
    end

    it "Create new adhoc hearing day and do not assign a room (room should be nil in DB)" do
      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: "17-Jan-2019", assign_room: false }
      expect(response).to be_successful
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 1, 17))
      expect(JSON.parse(response.body)["hearing"]["readable_request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq(nil)
    end

    it "Create new adhoc Central Office hearing day and assign room 2" do
      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: "17-Jan-2019", assign_room: true }
      expect(response).to be_successful
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 1, 17))
      expect(JSON.parse(response.body)["hearing"]["readable_request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq("2 (1W200B)")
    end

    it "Create new adhoc Travel hearing day and do not assign a room" do
      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:travel],
                                              scheduled_for: "17-Jan-2019",
                                              regional_office: "RO27",
                                              assign_room: false }
      expect(response).to be_successful
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 1, 17))
      expect(JSON.parse(response.body)["hearing"]["readable_request_type"]).to eq("Travel")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq(nil)
    end

    let(:may_hearing_days) do
      (1..HearingRooms::ROOMS.size).each do |n|
        create(
          :hearing_day,
          regional_office: "RO10",
          request_type: HearingDay::REQUEST_TYPES[:video],
          scheduled_for: Date.new(2019, 5, 14),
          room: n.to_s
        )
      end
    end

    it "Create new adhoc hearing day but no rooms available. Confirm error message received." do
      may_hearing_days

      post "/hearings/hearing_day", params: { regional_office: "RO10",
                                              request_type: HearingDay::REQUEST_TYPES[:video],
                                              scheduled_for: "14-May-2019", assign_room: true }
      expect(response).to have_http_status(404)
      expect(JSON.parse(response.body)["errors"][0]["title"])
        .to eq(COPY::ADD_HEARING_DAY_MODAL_VIDEO_HEARING_ERROR_MESSAGE_TITLE % "05/14/2019")
      expect(JSON.parse(response.body)["errors"][0]["detail"])
        .to eq(COPY::ADD_HEARING_DAY_MODAL_VIDEO_HEARING_ERROR_MESSAGE_DETAIL)
    end

    let(:mar_hearing_days) do
      (1..HearingRooms::ROOMS.size).each do |n|
        create(:hearing_day, scheduled_for: Date.new(2019, 3, 14), room: n.to_s)
      end
    end

    it "Create new adhoc hearing day on a full day. Room assignment not required, hence is empty string." do
      mar_hearing_days

      post "/hearings/hearing_day", params: { request_type: HearingDay::REQUEST_TYPES[:central],
                                              scheduled_for: "14-Mar-2019", assign_room: false }
      expect(response).to be_successful
      actual_date = Date.parse(JSON.parse(response.body)["hearing"]["scheduled_for"])
      expect(actual_date).to eq(Date.new(2019, 3, 14))
      expect(JSON.parse(response.body)["hearing"]["readable_request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing"]["room"]).to eq(nil)
    end
  end

  describe "Assign judge to hearing day" do
    let!(:hearing_day) { create(:hearing_day) }
    let!(:judge) { create(:user) }

    it "Assign a judge to a schedule day" do
      patch "/hearings/hearing_day/#{hearing_day.id}", params: { judge_id: judge.id }
      expect(response).to be_successful
      expect(JSON.parse(response.body)["judge_id"]).to eq(judge.id)
    end
  end

  describe "Show a hearing day with its children hearings" do
    let!(:regional_office) do
      create(:staff, stafkey: "RO13", stc4: 11)
    end
    let!(:hearing_day) { create(:hearing_day) }
    let!(:hearing) { create(:hearing, :with_tasks, hearing_day: hearing_day) }

    it "returns video children hearings" do
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day/" + hearing_day.id.to_s, headers: headers
      expect(response).to be_successful
      expect(JSON.parse(response.body)["hearing_day"]["readable_request_type"]).to eq("Central")
      expect(JSON.parse(response.body)["hearing_day"]["hearings"].count).to eq(1)
    end
  end

  describe "Get hearing schedule for a date range" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      HearingDay.create(
        [{ request_type: HearingDay::REQUEST_TYPES[:central], scheduled_for: "7-Jun-2019 09:00:00.000-4:00",
           room: "1" },
         { request_type: HearingDay::REQUEST_TYPES[:central], scheduled_for: "9-Jun-2019 13:00:00.000-4:00",
           room: "3", judge_id: create(:user, css_id: "BVARTONY") },
         { request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "15-Jun-2019 08:30:00.000-4:00",
           regional_office: "RO27", room: "4" },
         { request_type: HearingDay::REQUEST_TYPES[:travel], scheduled_for: "13-Jun-2019 08:30:00.000-4:00",
           regional_office: "RO27", room: "4" }]
      )
      Generators::VACOLS::TravelBoardSchedule.create(tbyear: 2019, tbstdate: "2019-01-30 00:00:00",
                                                     tbenddate: "2019-02-03 00:00:00", tbmem1: "111")
      Generators::VACOLS::Staff.create(sattyid: "111")
      Generators::VACOLS::Staff.create(sattyid: "105", sdomainid: "BVARTONY", snamel: "Randall", snamef: "Tony")
    end

    it "Get hearings for specified date range" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", params: { start_date: "2019-01-01", end_date: "2019-06-15" }, headers: headers
      expect(response).to be_successful
      expect(JSON.parse(response.body)["hearings"].size).to eq(4)
      # Passing locally, failing on Jenkins
      # expect(JSON.parse(response.body)["hearings"][1]["judge_last_name"]).to eq("Randall")
      # expect(JSON.parse(response.body)["hearings"][1]["judge_first_name"]).to eq("Tony")
      # expect(JSON.parse(response.body)["hearings"][2]["regional_office"]).to eq("Louisville, KY")
    end
  end

  describe "Get hearing schedule for an RO" do
    let!(:hearings) do
      RequestStore[:current_user] = user
      HearingDay.create(
        [{ request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "7-Jun-2019 09:00:00.000-4:00",
           room: "1", regional_office: "RO17" },
         { request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "9-Jun-2019 09:00:00.000-4:00",
           room: "3", regional_office: "RO27" },
         { request_type: HearingDay::REQUEST_TYPES[:travel], scheduled_for: "8-Jun-2019 09:00:00.000-4:00",
           room: "3", regional_office: "RO27" }]
      )
      Generators::VACOLS::TravelBoardSchedule.create(tbyear: 2019, tbstdate: "2019-01-30 00:00:00",
                                                     tbenddate: "2019-02-03 00:00:00", tbmem1: "111")
      Generators::VACOLS::Staff.create(sattyid: "111")
    end

    it "Get hearings for RO" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/hearing_day", params: { regional_office: "RO17", start_date: "2019-01-01",
                                             end_date: "2019-12-31" }, headers: headers
      expect(response).to be_successful
      expect(JSON.parse(response.body)["hearings"].size).to be(1)
    end
  end

  describe "Get hearings with veterans" do
    let!(:staff) { create(:staff, stafkey: "RO04", stc2: 2, stc3: 3, stc4: 4) }
    let!(:hearings) do
      RequestStore[:current_user] = user
      Generators::VACOLS::Staff.create(sattyid: "111")
      HearingDay.create(
        [{ request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "7-Mar-2019 09:00:00.000-4:00",
           room: "1", regional_office: "RO04" },
         { request_type: HearingDay::REQUEST_TYPES[:video], scheduled_for: "9-Mar-2019 09:00:00.000-4:00",
           room: "3", regional_office: "RO04" },
         { request_type: HearingDay::REQUEST_TYPES[:travel], scheduled_for: "8-Mar-2019 09:00:00.000-4:00",
           room: "3", regional_office: "RO04" }]
      )
    end

    it "Get hearings with veterans" do
      hearings
      headers = {
        "ACCEPT" => "application/json"
      }
      get "/hearings/schedule/assign/hearing_days", params: { regional_office: "RO04" }, headers: headers
      expect(response).to be_successful
      expect(JSON.parse(response.body)["hearing_days"].size).to be(3)
    end
  end

  describe "Delete a hearing day" do
    let!(:hearing_day) { create(:hearing_day) }

    it "Deletes the hearing day" do
      delete "/hearings/hearing_day/#{hearing_day.id}"
      expect(response).to be_successful
      expect(HearingDay.all.count).to eq(0)
      expect(HearingDay.with_deleted.count).to eq(1)
    end
  end
end
