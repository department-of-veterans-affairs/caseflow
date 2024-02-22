# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  include CorrespondenceTaskHelpers
  # alias this to avoid the method name collision
  alias_method :create_efolderupload_task, :create_efolderupload_failed_task

  context "correspondece cases feature toggle" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      @correspondence_uuid = "123456789"
    end

    it "routes user to /under_construction if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence"
      expect(page).to have_current_path("/under_construction")
    end

    it "routes to correspondence cases if feature toggle is enabled" do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence"
      expect(page).to have_current_path("/queue/correspondence")
    end
  end

  context "correspondence cases form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(user: current_user)
      @correspondence_uuid = "123456789"
    end
  end

  context "correspondence tasks in-progress tab" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      20.times do
        correspondence = create(:correspondence)
        parent_task = create_correspondence_intake(correspondence, current_user)
        create_efolderupload_task(correspondence, parent_task, user:current_user)
      end
      # Used to mock a single task to compare task sorting
      EfolderUploadFailedTask.first.update!(type: "ReviewPackageTask")
      EfolderUploadFailedTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10),
        updated_by_id: current_user.id
      )
      EfolderUploadFailedTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2024, 10, 10),
        updated_by_id: current_user.id
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the in progress tab" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Correspondence in progress")
    end

    it "uses veteran details sort correctly." do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Veteran Details']").click
      first_vet_info = page.all("#task-link")[0].text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Veteran Details']").click
      last_vet_info = page.all("#task-link")[0].text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == first_vet_info)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == last_vet_info)
    end

    it "uses VA DOR sort correctly." do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by VA DOR']").click
      first_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by VA DOR']").click
      last_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_date)
      # return to Z-A, compare details again
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_date)
    end

    it "uses tasks sort correctly." do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Tasks']").click
      first_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Tasks']").click
      second_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Tasks']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == first_task_type)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Tasks']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == second_task_type)
    end

    it "uses days waiting sort correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Days Waiting']").click
      first_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Days Waiting']").click
      second_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == first_day_amount)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == second_day_amount)
    end

    it "uses notes sort correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Notes']").click
      first_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Notes']").click
      second_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == first_note)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == second_note)
    end

    it "uses receipt date between filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2024")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses uses task filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find("label", text: "Review Package Task (1)").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end
  end

  context "correspondence tasks completed tab" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeamSupervisor.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      20.times do
        correspondence = create(:correspondence)
        correspondence.root_task.update!(status: Constants.TASK_STATUSES.completed,
                                         closed_at: rand(6 * 24 * 60).minutes.ago)
      end
    end

    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
    end

    it "displays all completed correspondence tasks" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"
      expect(page).to have_content("Completed correspondence:")
      expect(page).to have_content("Viewing 1-15 of 20 total")
      expect(page).to have_button("Next")
      expect(page).not_to have_button("Previous")

      click_button("Next", match: :first)
      expect(page).to have_content("Viewing 16-20 of 20 total")
      expect(page).to have_button("Previous")
      expect(page).not_to have_button("Next")

      click_button("Previous", match: :first)
      expect(page).to have_content("Viewing 1-15 of 20 total")
    end

    it "displays all correspondence tasks sorted by date completed" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"
      find("[aria-label='Sort by Date Completed']").click

      dates = all("tbody > tr > td:nth-child(3)").map(&:text)
      expect(dates).to eq(dates.sort.reverse)

      find("[aria-label='Sort by Date Completed']").click
      dates = all("tbody > tr > td:nth-child(3)").map(&:text)
      expect(dates).to eq(dates.sort)
    end

    it "filters date column with 'between' the dates" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-0").click
      current_date = Time.zone.today
      start_date = current_date.strftime("%m/%d/%Y")
      end_date = (current_date + 1).strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: start_date)
      all("div.input-container > input")[1].fill_in(with: end_date)

      expect(page).to have_button("Apply filter", disabled: false)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "filters date column with 'before' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-1").click
      current_date = Time.zone.today
      start_date = (current_date - 1).strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: start_date)
      expect(page).to have_button("Apply filter", disabled: false)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "filters date column with 'after' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-2").click
      current_date = Time.zone.yesterday
      after_date = (current_date + 1).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: after_date)
      expect(page).to have_button("Apply filter", disabled: false)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "filters date column with 'on' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-3").click
      current_date = Time.zone.today
      on_this_date = current_date.strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: on_this_date)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "sorts by Veteran Details column" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=veteranDetailsColumn&order=asc"
      find("[aria-label='Sort by Veteran Details']").click

      veterans = all("#task-link").map(&:text)
      expect(veterans).to eq(veterans.sort.reverse)

      find("[aria-label='Sort by Veteran Details']").click
      veterans = all("#task-link").map(&:text)
      expect(veterans).to eq(veterans.sort)
    end

    it "sorts by Notes column" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=notes&order=asc"
      find("[aria-label='Sort by Notes']").click

      notes = all("tbody > tr > td:nth-child(4)").map(&:text)
      expect(notes).to eq(notes.sort.reverse)

      find("[aria-label='Sort by Notes']").click
      notes = all("tbody > tr > td:nth-child(4)").map(&:text)
      expect(notes).to eq(notes.sort)
    end
  end

  context "correspondence cases action required tab" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeamSupervisor.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end
    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      5.times do
        corres_array = (1..4).map { create(:correspondence) }
        task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_id: corres.id,
            appeal_type: "Correspondence",
            assigned_to: MailTeamSupervisor.singleton,
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end
       # Used to mock a single task to compare task sorting
       ReassignPackageTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10),
        updated_by_id: current_user.id
      )
       ReassignPackageTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10),
        updated_by_id: current_user.id
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the action required tab" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      expect(page).to have_content("Correspondence with pending requests:")
    end

    it "uses veteran details sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Veteran Details']").click
      first_vet_info = page.all("#task-link")[0].text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Veteran Details']").click
      last_vet_info = page.all("#task-link")[0].text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == first_vet_info)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == last_vet_info)
    end

    it "uses VA DOR sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by VA DOR']").click
      first_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by VA DOR']").click
      last_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_date)
      # return to Z-A, compare details again
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_date)
    end

    it "uses action type sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Action Type']").click
      first_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Action Type']").click
      second_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Action Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == first_task_type)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Action Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == second_task_type)
    end

    it "uses days waiting sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Days Waiting']").click
      first_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Days Waiting']").click
      second_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == first_day_amount)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == second_day_amount)
    end

    it "uses notes sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Notes']").click
      first_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Notes']").click
      second_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == first_note)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == second_note)
    end

    it "uses receipt date between filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2024")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end
  end

  context "correspondence cases unassigned tab" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeamSupervisor.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      5.times do
        corres_array = (1..4).map { create(:correspondence) }
        task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_id: corres.id,
            appeal_type: "Correspondence",
            assigned_to: MailTeamSupervisor.singleton,
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end

      # Used to mock a single task to compare task sorting
      ReassignPackageTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10),
        updated_by_id: current_user.id
      )
      ReassignPackageTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10),
        updated_by_id: current_user.id
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the unassigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      expect(page).to have_content("Correspondence owned by the Mail team are unassigned to an individual:")
      expect(page).to have_content("Assign to mail team user")
      expect(page).to have_button("Assign")
      expect(page).to have_button("Auto assign correspondence")
    end

    it "uses veteran details sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Veteran Details']").click
      first_vet_info = page.all("#task-link")[0].text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Veteran Details']").click
      last_vet_info = page.all("#task-link")[0].text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == first_vet_info)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == last_vet_info)
    end

    it "uses VA DOR sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by VA DOR']").click
      first_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by VA DOR']").click
      last_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_date)
      # return to Z-A, compare details again
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_date)
    end

    it "uses days waiting sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Days Waiting']").click
      first_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Days Waiting']").click
      second_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == first_day_amount)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == second_day_amount)
    end

    it "uses notes sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Notes']").click
      first_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Notes']").click
      second_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == first_note)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == second_note)
    end

    it "uses receipt date between filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-2").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2024")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end
  end

  context "correspondence cases assigned tab" do
    let(:current_user) { create(:user) }
    before :each do
      MailTeamSupervisor.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      5.times do
        corres_array = (1..4).map { create(:correspondence) }
        task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_id: corres.id,
            appeal_type: "Correspondence",
            assigned_to: MailTeamSupervisor.singleton,
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end

      # Used to mock a single task to compare task sorting
      ReassignPackageTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10),
        updated_by_id: current_user.id
      )
      ReassignPackageTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10),
        updated_by_id: current_user.id
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the assigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Correspondence that is currently assigned to mail team users:")
      expect(page).to have_content("Assign to mail team user")
      expect(page).to have_button("Reassign")
    end

    it "uses veteran details sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Veteran Details']").click
      first_vet_info = page.all("#task-link")[0].text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Veteran Details']").click
      last_vet_info = page.all("#task-link")[0].text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == first_vet_info)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == last_vet_info)
    end

    it "uses VA DOR sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by VA DOR']").click
      first_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by VA DOR']").click
      last_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_date)
      # return to Z-A, compare details again
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_date)
    end

    it "uses days waiting sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Days Waiting']").click
      first_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Days Waiting']").click
      second_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == first_day_amount)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == second_day_amount)
    end

    it "uses notes sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Notes']").click
      first_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Notes']").click
      second_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == first_note)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == second_note)
    end

    it "uses receipt date between filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-2").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2024")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end
  end
end
