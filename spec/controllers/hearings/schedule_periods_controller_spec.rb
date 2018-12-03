RSpec.describe Hearings::SchedulePeriodsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Build HearSched"]) }
  let!(:ro_schedule_period) { create(:ro_schedule_period) }
  let!(:judge_schedule_period) { create(:judge_schedule_period) }

  context "index" do
    it "returns all schedule periods" do
      get :index, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["schedule_periods"].size).to eq 2
    end
  end

  context "show" do
    it "returns a schedule period and its hearing days" do
      get :show, params: { schedule_period_id: ro_schedule_period.id }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)

      allocated_count = ro_schedule_period.allocations.map(&:allocated_days).inject(:+).ceil
      expect(response_body["schedule_period"]["hearing_days"].count).to eq allocated_count
      expect(response_body["schedule_period"]["file_name"]).to eq "validRoSpreadsheet.xlsx"
      expect(response_body["schedule_period"]["start_date"]).to eq "2018-01-01"
      expect(response_body["schedule_period"]["end_date"]).to eq "2018-06-01"
    end
  end

  context "show judge" do
    let!(:co_hearing_days) do
      get_unique_dates_between(judge_schedule_period.start_date, judge_schedule_period.end_date, 5).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: "VIDEO RO13")
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: nil)
      end
    end

    it "returns a schedule period and its hearing days with judges assigned", skip: "Fails intermittently" do
      get :show, params: { schedule_period_id: judge_schedule_period.id }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)

      num_of_co_days = co_hearing_days.count { |day| day.hearing_date.wednesday? }
      expect(response_body["schedule_period"]["hearing_days"].count).to eq 5 + num_of_co_days
      expect(response_body["schedule_period"]["file_name"]).to eq "validJudgeSpreadsheet.xlsx"
      expect(response_body["schedule_period"]["start_date"]).to eq "2018-04-01"
      expect(response_body["schedule_period"]["end_date"]).to eq "2018-09-30"
    end
  end

  context "create" do
    it "creates a new schedule period" do
      id = SchedulePeriod.last.id + 1
      base64_header = "data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,"
      post :create, params: {
        schedule_period: {
          type: "RoSchedulePeriod",
          start_date: "2018/01/01",
          end_date: "2018/06/01",
          file_name: "fakeFileName.xlsx"
        },
        file: base64_header + Base64.encode64(File.open("spec/support/validRoSpreadsheet.xlsx").read)
      }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq id
    end

    it "returns an error for an invalid spreadsheet" do
      error = "Validation failed: HearingSchedule::ValidateRoSpreadsheet::RoTemplateNotFollowed"
      base64_header = "data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,"
      post :create, params: {
        schedule_period: {
          type: "RoSchedulePeriod",
          start_date: "2018/01/01",
          end_date: "2018/06/01",
          file_name: "fakeFileName.xlsx"
        },
        file: base64_header + Base64.encode64(File.open("spec/support/roTemplateNotFollowed.xlsx").read)
      }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["error"]).to eq error
    end
  end

  context "persist full schedule for a schedule period" do
    it "persists a schedule for a given schedulePeriod id" do
      put :update, params: {
        schedule_period_id: ro_schedule_period.id
      }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq ro_schedule_period.id

      # Invoking separate controller to verify that we persisted
      # the schedule for the given date range.
      @controller = Hearings::HearingDayController.new
      get :index, params: { start_date: "2018-01-01", end_date: "2018-06-01" }, as: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)["hearings"].size).to be_between(355, 359)
    end

    it "persist twice and second request should return an error" do
      put :update, params: {
        schedule_period_id: ro_schedule_period.id
      }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq ro_schedule_period.id

      put :update, params: {
        schedule_period_id: ro_schedule_period.id
      }, as: :json
      expect(response.status).to eq 422
    end
  end

  context "assign judges to full schedule for a schedule period" do
    let!(:hearing_days) do
      create(:case_hearing, hearing_type: "C", hearing_date: Date.new(2018, 5, 1), folder_nr: "VIDEO RO13")
      create(:case_hearing, hearing_type: "C", hearing_date: Date.new(2018, 5, 8), folder_nr: "VIDEO RO13")
      create(:case_hearing, hearing_type: "C", hearing_date: Date.new(2018, 5, 15), folder_nr: "VIDEO RO13")
      create(:case_hearing, hearing_type: "C", hearing_date: Date.new(2018, 5, 22), folder_nr: "VIDEO RO13")
      create(:case_hearing, hearing_type: "C", hearing_date: Date.new(2018, 5, 29), folder_nr: "VIDEO RO13")
    end

    it "update judge assignments for a given schedulePeriod id" do
      put :update, params: {
        schedule_period_id: judge_schedule_period.id
      }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq judge_schedule_period.id
    end
  end

  context "download spreadsheet from S3" do
    it "downloads from S3 and saves in client computer" do
      get :download, params: {
        schedule_period_id: ro_schedule_period.id
      }, as: :json
      expect(response.status).to eq 200
    end
  end
end
