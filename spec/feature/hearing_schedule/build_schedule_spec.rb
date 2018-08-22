RSpec.feature "Build Hearing Schedule" do
  context "Build RO Hearing Schedule" do
    let!(:current_user) do
      User.authenticate!(roles: ["Build HearSched"])
    end

    scenario "RO assignment process" do
      visit "hearings/schedule/build"
      click_on "Upload files"
      find("label", text: "RO/CO hearings").click
      attach_file("ro_co_file_upload", Rails.root + "spec/support/validRoSpreadsheet.xlsx", visible: false)
      fill_in "startDate", with: "01012018"
      fill_in "endDate", with: "05312018"
      click_on "Continue"
      page.has_content?("We have assigned your video hearings")
      expect(SchedulePeriod.count).to eq(1)
      expect(RoNonAvailability.count).to eq(227)
      expect(CoNonAvailability.count).to eq(4)
      expect(Allocation.count).to eq(57)
      allocation_count = Allocation.all.map(&:allocated_days).inject(:+).ceil
      expect(allocation_count).to eq(358)
      click_on "Confirm assignments"
      click_on "Confirm upload"
      expect(page).not_to have_content("We are uploading to VACOLS.")
      expect(page).to have_content("You have successfully assigned hearings between 01/01/2018 and 05/31/2018")
      hearing_day_count = HearingDay.load_days(Date.new(2018, 1, 1), Date.new(2018, 5, 31)).flatten
        .select do |hearing_day|
          hearing_day.try(:folder_nr) && hearing_day.folder_nr.include?("VIDEO")
        end.count
      expect(hearing_day_count).to eq(allocation_count)
    end
  end
end
