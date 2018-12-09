require "rails_helper"

RSpec.feature "Schedule Veteran For A Hearing" do
 let!(:current_user) do
    User.authenticate!(roles: ["Build HearSched"])
  end


  scenario "RO assignment process" do
   
    visit "hearings/schedule/build"
    click_on "Upload files"
    
    find("label", text: "RO/CO hearings").click
    attach_file("ro_co_file_upload", Rails.root + "spec/support/validRoSpreadsheet.xlsx", visible: false)
    fill_in "startDate", with: "01012018"
    fill_in "endDate", with: "01012019"
    
    click_on "Continue"
    
    expect(page.find("h2.usa-alert-heading", wait: 3000).text).to include("We have assigned your video hearings")
    expect(SchedulePeriod.count).to eq(1)
    expect(RoNonAvailability.count).to eq(227)
    expect(CoNonAvailability.count).to eq(4)
    expect(Allocation.count).to eq(57)
    allocation_count = Allocation.all.map(&:allocated_days).inject(:+).ceil
    expect(allocation_count).to eq(358)
    
    click_on "Confirm assignments"
    click_on "Confirm upload"

    expect(page).not_to have_content("We are uploading to VACOLS.", wait: 15)
    expect(page).to have_content("You have successfully assigned hearings between 01/01/2018 and 01/01/2019")
    
    hearing_day_count = HearingDay.load_days(Date.new(2018, 1, 1), Date.new(2019, 1, 1)).flatten
      .select do |hearing_day|
      hearing_day.key?(:regional_office) && hearing_day[:regional_office].start_with?("R")
    end.count
    
    expect(hearing_day_count).to eq(allocation_count)
  end

  scenario "Schedule Veteran process" do
    visit "hearings/schedule/assign"
  end
end