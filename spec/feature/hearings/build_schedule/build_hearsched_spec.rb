# frozen_string_literal: true

RSpec.feature "Build Hearing Schedule for Build HearSched", :all_dbs do
  let!(:current_user) do
    User.authenticate!(roles: ["Build HearSched"])
  end

  # rubocop:disable Metrics/AbcSize
  def assignment_process(file, start_date, end_date)
    # Navigate to the build hearings schedule screen
    visit "hearings/schedule/build"

    # Select the valid RO spreadsheet to upload
    click_on "Upload files"
    find("label", text: "RO/CO hearings").click

    # Set the file based on request type
    attach_file("ro_co_file_upload", Rails.root + "spec/support/" + file, visible: false)

    # Fill in the required firleds to continue
    fill_in "startDate", with: start_date.tr("/", "")
    fill_in "endDate", with: end_date.tr("/", "")
    click_on "Continue"

    # Ensure the page has the expected content
    expect(page).to have_content("We have assigned your hearings days", wait: 30)
    expect(SchedulePeriod.count).to eq(1)
    expect(Allocation.count).to eq(56)

    # Confirm the assignments and upload the document
    click_on "Confirm assignments"
    click_on "Confirm upload"

    # Ensure a successful upload
    expect(page).not_to have_content("We are uploading to VACOLS.", wait: 30)
    expect(page).to have_content(
      "You have successfully assigned hearings between #{start_date} and #{end_date}",
      wait: 60
    )
  end
  # rubocop:enable Metrics/AbcSize

  context "Build RO Hearing Schedule" do
    scenario "RO assignment process" do
      assignment_process("validRoSpreadsheet.xlsx", "01/01/2018", "05/31/2018")
      expect(RoNonAvailability.count).to eq(216)
      expect(CoNonAvailability.count).to eq(4)

      # Compare the Central Office hearing days
      co_hearing_days = HearingDay.where(request_type: "C")
      expect(co_hearing_days.count). to eq(22)

      # Retrieve all the virtual hearing days
      virtual_hearing_days = HearingDay.where(request_type: "R")

      # Retrieve the hearing days with no room and no regional office to get all NVHQ hearing days
      national_virtual_hearing_days = virtual_hearing_days.select { |hearing_day| hearing_day.regional_office.nil? }
      expect(national_virtual_hearing_days.count). to eq(25)

      # Check the allocation for hearing days without rooms
      allocation_with_room_count = Allocation.all.map(&:allocated_days).inject(:+).ceil
      expect(allocation_with_room_count).to eq(343)

      # Check the allocation for hearing days with rooms
      allocation_without_room_count = Allocation.all.map(&:allocated_days_without_room).inject(:+).ceil
      expect(allocation_without_room_count).to eq(605)

      # Compare the Video hearing days
      video_hearing_days = HearingDay.where(request_type: "V")

      # Ensure all allocations have hearing days created
      expect(video_hearing_days.count).to eq(allocation_with_room_count)
      expect(virtual_hearing_days.count).to eq(allocation_without_room_count)
    end

    scenario "RO Virtual-only assignment process" do
      assignment_process("validRoNoRoomsSpreadsheet.xlsx", "04/01/2021", "06/30/2021")
      expect(RoNonAvailability.count).to eq(164)
      expect(CoNonAvailability.count).to eq(3)

      # Compare the Central Office hearing days
      co_hearing_days = HearingDay.where(request_type: "C")
      expect(co_hearing_days.count). to eq(13)

      # Retrieve all the virtual hearing days
      virtual_hearing_days = HearingDay.where(request_type: "R")

      # Retrieve the hearing days with no room and no regional office to get all NVHQ hearing days
      national_virtual_hearing_days = virtual_hearing_days.select { |hearing_day| hearing_day.regional_office.nil? }
      expect(national_virtual_hearing_days.count). to eq(120)

      # Check the allocation virtual count
      allocation_count = Allocation.all.map(&:allocated_days_without_room).inject(:+).ceil
      expect(allocation_count).to eq(2101)

      # Validate that all days with no rooms have been created
      expect(virtual_hearing_days.count).to eq(allocation_count)

      # Confirm that no rooms were assigned
      expect(virtual_hearing_days.map(&:room).any?).to eq(false)
    end
  end

  context "Build Judge Hearing Schedule" do
    let!(:judge_stuart) { create(:user, full_name: "Stuart Huels", css_id: "BVAHUELS") }
    let!(:judge_doris) { create(:user, full_name: "Doris Lamphere", css_id: "BVALAMPHERE") }

    let!(:hearing_days) do
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:central],
             judge: judge_doris,
             scheduled_for: Date.new(2018, 4, 2))
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:central],
             judge: judge_stuart,
             scheduled_for: Date.new(2018, 4, 20))
    end

    scenario "Successful Judge assignment process" do
      visit "hearings/schedule/build"
      click_on "Upload files"
      find("label", text: "Judge assignment").click
      attach_file("judge_file_upload", Rails.root + "spec/support/validJudgeSpreadsheet.xlsx", visible: false)
      click_on "Continue"

      expect(page).to have_content("We have assigned your judges", wait: 30)
      expect(find("tbody").find_all("tr").length).to eq(2)

      find("tbody").find_all("tr").each do |row|
        judge_first_name = judge_stuart.full_name.split(" ")[0]
        judge_last_name = judge_stuart.full_name.split(" ")[1]
        expect(row).to have_content("#{judge_last_name}, #{judge_first_name}")
      end

      click_on "Confirm assignments"
      expect(page).to have_content("Loading", wait: 30)
      expect(page).to have_content("Successfully assigned judges to the provided hearing days", wait: 30)

      HearingDay.all.each do |hearing_day|
        expect(hearing_day.reload.judge).to eq(judge_stuart)
      end
    end

    scenario "Invalid Judge assignment process" do
      visit "hearings/schedule/build"
      click_on "Upload files"
      find("label", text: "Judge assignment").click
      attach_file("judge_file_upload", Rails.root + "spec/support/judgeNotInDb.xlsx", visible: false)
      click_on "Continue"

      error_message = "These judges are not in the database: [[\"456\", \"Huels, Stuart\"]]"
      expect(page).to have_content(error_message, wait: 30)
    end
  end
end
