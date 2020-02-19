# frozen_string_literal: true

RSpec.describe Hearings::SchedulePeriodsController, :all_dbs, type: :controller do
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

      ro_allocated_count = ro_schedule_period.allocations.map(&:allocated_days).inject(:+).ceil
      co_hearing_days_count = HearingSchedule::GenerateHearingDaysSchedule.new(ro_schedule_period)
        .generate_co_hearing_days_schedule.size
      allocated_count = ro_allocated_count + co_hearing_days_count
      expect(response_body["schedule_period"]["hearing_days"].count).to eq allocated_count
      expect(response_body["schedule_period"]["file_name"]).to eq "validRoSpreadsheet.xlsx"
      expect(response_body["schedule_period"]["start_date"]).to eq "2018-01-01"
      expect(response_body["schedule_period"]["end_date"]).to eq "2018-06-01"
    end
  end

  context "show judge" do
    let!(:co_hearing_days) do
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 1),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 7),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 16),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 22),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 23),
             regional_office: "RO13")
    end

    it "returns a schedule period and its hearing days with judges assigned" do
      get :show, params: { schedule_period_id: judge_schedule_period.id }, as: :json
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)

      expect(response_body["schedule_period"]["hearing_days"].count).to eq 5
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
          file_name: "fakeFileName.xlsx",
          file: base64_header + Base64.encode64(File.open("spec/support/validRoSpreadsheet.xlsx").read)
        }
      }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["id"]).to eq id
    end

    it "returns an error for an invalid spreadsheet" do
      error = "The RO non-availability template was not followed. Redownload the template and try again."
      base64_header = "data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,"
      post :create, params: {
        schedule_period: {
          type: "RoSchedulePeriod",
          start_date: "2018/01/01",
          end_date: "2018/06/01",
          file_name: "fakeFileName.xlsx",
          file: base64_header + Base64.encode64(File.open("spec/support/roTemplateNotFollowed.xlsx").read)
        }
      }
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["error"]).to include error
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
      expect(response).to be_successful
      expect(JSON.parse(response.body)["hearings"].size).to eq(427)
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
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 1),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 8),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 15),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 22),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 5, 29),
             regional_office: "RO13")
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
