# frozen_string_literal: true

RSpec.feature "Build Hearing Schedule for Build HearSched", :all_dbs do
  let!(:current_user) do
    User.authenticate!(roles: ["Build HearSched"])
  end

  context "Build RO Hearing Schedule" do
    scenario "RO assignment process" do
      visit "hearings/schedule/build"
      click_on "Upload files"
      find("label", text: "RO/CO hearings").click
      attach_file("ro_co_file_upload", Rails.root + "spec/support/validRoSpreadsheet.xlsx", visible: false)
      fill_in "startDate", with: "01012018"
      fill_in "endDate", with: "05312018"
      click_on "Continue"
      expect(page).to have_content("We have assigned your video hearings", wait: 30)
      expect(SchedulePeriod.count).to eq(1)
      expect(RoNonAvailability.count).to eq(216)
      expect(CoNonAvailability.count).to eq(4)
      expect(Allocation.count).to eq(55)
      allocation_count = Allocation.all.map(&:allocated_days).inject(:+).ceil
      expect(allocation_count).to eq(350)
      click_on "Confirm assignments"
      click_on "Confirm upload"
      expect(page).not_to have_content("We are uploading to VACOLS.", wait: 30)
      expect(page).to have_content("You have successfully assigned hearings between 01/01/2018 and 05/31/2018")
      video_hearing_days = HearingDay.where(request_type: "V")
      expect(video_hearing_days.count).to eq(allocation_count)
      co_hearing_days = HearingDay.where(request_type: "C")
      expect(co_hearing_days.count). to eq(84)
    end
  end

  context "Build Judge Hearing Schedule" do
    before do
      create(:staff, sattyid: "860", snamef: "Stuart", snamel: "Huels")
      create(:staff, sattyid: "861", snamef: "Doris", snamel: "Lamphere")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:central],
             scheduled_for: Date.new(2018, 4, 2))
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:central],
             scheduled_for: Date.new(2018, 4, 20))
    end

    scenario "Judge assignment process" do
      visit "hearings/schedule/build"
      click_on "Upload files"
      find("label", text: "Judge non-availability").click
      attach_file("judge_file_upload", Rails.root + "spec/support/validJudgeSpreadsheet.xlsx", visible: false)
      fill_in "startDate", with: "04012018"
      fill_in "endDate", with: "04302018"
      click_on "Continue"
      expect(page).to have_content("We have assigned your judges", wait: 30)
      expect(SchedulePeriod.count).to eq(1)
      expect(JudgeNonAvailability.count).to eq(3)
      click_on "Confirm assignments"
      click_on "Confirm upload"
      expect(page).not_to have_content("We are uploading to VACOLS.", wait: 15)
      expect(page).to have_content("You have successfully assigned judges to hearings", wait: 30)
      hearing_days = HearingDayRange.new(Date.new(2018, 4, 1), Date.new(2018, 4, 30)).load_days
      vlj_ids_count = hearing_days.pluck(:judge_id).compact.count
      expect(vlj_ids_count).to eq(2)
    end
  end
end
