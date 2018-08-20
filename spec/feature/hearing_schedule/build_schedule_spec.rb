RSpec.feature "Build Hearing Schedule" do

  context "Build RO Hearing Schedule" do

    let!(:current_user) do
      User.authenticate!(roles: ["Build HearSched"])
    end

    scenario "Upload a spreadsheet" do
      visit "hearings/schedule/build"
      click_on "Upload files"

      find("What-are-you-uploading-_RoSchedulePeriod").click

      attach_file("Select a file for upload", "spec/support/validRoSpreadsheet.xlsx")
    end
  end
end
