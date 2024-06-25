# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  include CorrespondenceTaskHelpers
  # alias this to avoid the method name collision
  alias_method :create_efolderupload_task, :create_efolderupload_failed_task

  context "correspondece cases feature toggle" do
    let(:current_user) { create(:user) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
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
      expect(current_path.include?("/queue/correspondence")).to eq true
    end
  end

  context "correspondence cases form shell" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }
    let(:veteran) { create(:veteran) }

    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence_uuid = "123456789"
      10.times do
        create(
          :correspondence,
          :with_single_doc,
          assigned_to: current_user,
          veteran_id: veteran.id,
          uuid: SecureRandom.uuid,
          va_date_of_receipt: Time.zone.local(2023, 1, 1)
        )
      end
    end
  end

  context "correspondence tasks in-progress tab" do
    let(:current_user) { create(:user) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      20.times do
        correspondence = create(:correspondence)
        parent_task = create_correspondence_intake(correspondence, current_user)
        create_efolderupload_task(correspondence, parent_task)
      end
      # Used to mock a single task to compare task sorting
      EfolderUploadFailedTask.first.update!(type: "ReviewPackageTask")
      EfolderUploadFailedTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      EfolderUploadFailedTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2024, 10, 10)
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
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      current_date = Time.zone.today
      my_date = current_date.strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses uses task filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[2].click
      find("label", text: "Review Package Task (1)").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end
  end

  context "correspondence tasks completed tab" do
    let(:current_user) { create(:correspondence_auto_assignable_user, :super_user) }

    before do
      20.times do
        correspondence_root_task_completion
      end
    end

    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(user: current_user)
    end

    it "displays all completed correspondence tasks" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
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
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Sort by Date Completed']").click

      dates = all("tbody > tr > td:nth-child(3)").map(&:text)
      expect(dates).to eq(dates.sort.reverse)

      find("[aria-label='Sort by Date Completed']").click
      dates = all("tbody > tr > td:nth-child(3)").map(&:text)
      expect(dates).to eq(dates.sort)
    end

    it "filters date column with 'between' the dates" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-0").click
      current_date = Time.zone.today
      start_date = (current_date - 1).strftime("%m/%d/%Y")
      end_date = current_date.strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: start_date)
      all("div.input-container > input")[1].fill_in(with: end_date)

      expect(page).to have_button("Apply filter", disabled: false)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "filters date column with 'before' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-1").click
      current_date = Time.zone.today
      start_date = (current_date - 3).strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: start_date)
      expect(page).to have_button("Apply filter", disabled: false)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "filters date column with 'after' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"

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
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"

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
      CorrespondenceRootTask.all.limit(5).each { |crt| crt.update(status: "assigned") }
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      unsorted_veterans = all("#task-link").map(&:text)
      find("[aria-label='Sort by Veteran Details']").click
      sorted_veterans = all("#task-link").map(&:text)

      expect(sorted_veterans).to eq(unsorted_veterans.sort.reverse)

      find("[aria-label='Sort by Veteran Details']").click
      sorted_veterans = all("#task-link").map(&:text)

      expect(sorted_veterans).to eq(unsorted_veterans.sort)
    end

    it "sorts by Notes column" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Sort by Notes']").click

      notes = all("tbody > tr > td:nth-child(5)").map(&:text)
      expect(notes).to eq(notes.sort.reverse)

      find("[aria-label='Sort by Notes']").click
      notes = all("tbody > tr > td:nth-child(5)").map(&:text)
      expect(notes).to eq(notes.sort)
    end
  end

  context "correspondence cases action required tab" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }

    before :each do
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
            appeal_type: "Correspondence",
            appeal_id: corres.id,
            assigned_to: InboundOpsTeam.singleton,
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end
      # Used to mock a single task to compare task sorting
      ReassignPackageTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      ReassignPackageTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
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
      using_wait_time(10) do
        expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == second_day_amount)
      end
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
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      current_date = Time.zone.today
      my_date = (current_date - 4).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end
  end

  context "correspondence cases unassigned tab" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }

    before :each do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
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
            appeal_type: "Correspondence",
            assigned_to: InboundOpsTeam.singleton,
            appeal_id: corres.id,
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end

      # Used to mock a single task to compare task sorting
      ReassignPackageTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      ReassignPackageTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
    end

    it "successfully loads the unassigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      expect(page).to have_content("Correspondence owned by the Mail team are unassigned to an individual:")
      expect(page).to have_content("Assign to Inbound Ops Team user")
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
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-2").click
      current_date = Time.zone.today
      my_date = (current_date - 5).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end
  end

  context "correspondence cases assigned tab" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }

    before :each do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      (1..10).map { create(:correspondence, :with_correspondence_intake_task) }
      10.times do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_user, status: "assigned")
        rpt.save!
      end
      10.times do
        corr = create(:correspondence)

        rpt = ReviewPackageTask.find_by(appeal_id: corr.id)

        EfolderUploadFailedTask.create!(
          parent_id: rpt.id,
          appeal_id: corr.id,
          appeal_type: "Correspondence",
          assigned_to: current_user,
          assigned_by_id: rpt.assigned_to_id
        )
      end

      # Used to mock a single task to compare task sorting
      EfolderUploadFailedTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      EfolderUploadFailedTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the assigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Correspondence that is currently assigned to mail team users:")
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Reassign", disabled: true)
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

    it "use tasks filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      find("[aria-label='Filter by task']").click
      find("label", text: "Correspondence Intake Task (10)").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
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
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-1").click
      current_date = Time.zone.today
      my_date = (current_date - 5).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-2").click
      current_date = Time.zone.today
      my_date = (current_date - 5).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end
  end

  context "Your Correspondence assigned tab" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }

    before :each do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      (1..10).map { create(:correspondence, :with_correspondence_intake_task) }
      10.times do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_user, status: "assigned")
        rpt.save!
      end
      10.times do
        corr = create(:correspondence)

        rpt = ReviewPackageTask.find_by(appeal_id: corr.id)

        EfolderUploadFailedTask.create!(
          parent_id: rpt.id,
          appeal_id: corr.id,
          appeal_type: "Correspondence",
          assigned_to: current_user,
          assigned_by_id: rpt.assigned_to_id
        )
      end

      # Used to mock a single task to compare task sorting
      EfolderUploadFailedTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      EfolderUploadFailedTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the assigned tab" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
    end

    it "uses VA DOR sort correctly." do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
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

    it "uses notes sort correctly" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
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
  end

  context "Your Correspondence completed tab" do
    let(:current_user) { create(:user) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      (1..10).map { create(:correspondence, :with_correspondence_intake_task) }
      10.times do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_user, status: "completed")
        rpt.save!
      end
      10.times do
        corr = create(:correspondence)

        rpt = ReviewPackageTask.find_by(appeal_id: corr.id)

        EfolderUploadFailedTask.create!(
          parent_id: rpt.id,
          appeal_id: corr.id,
          appeal_type: "Correspondence",
          assigned_to: current_user,
          assigned_by_id: rpt.assigned_to_id
        )
      end

      # Used to mock a single task to compare task sorting
      EfolderUploadFailedTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      EfolderUploadFailedTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the completed tab" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Completed correspondence")
    end

    it "uses veteran details sort correctly." do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
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
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
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

    it "sorts by Notes column" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Sort by Notes']").click

      notes = all("tbody > tr > td:nth-child(4)").map(&:text)
      expect(notes).to eq(notes.sort.reverse)

      find("[aria-label='Sort by Notes']").click
      notes = all("tbody > tr > td:nth-child(4)").map(&:text)
      expect(notes).to eq(notes.sort)
    end

    it "uses receipt date between filter correctly" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      current_date = Time.zone.today
      my_date = current_date.strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end
  end

  context "correspondence cases pending tab" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }

    before :each do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      5.times do
        corres_array = (1..4).map { create(:correspondence) }
        task_array = [CavcCorrespondenceCorrespondenceTask,
                      CongressionalInterestCorrespondenceTask,
                      DeathCertificateCorrespondenceTask,
                      PrivacyActRequestCorrespondenceTask]

        corres_array.each_with_index do |corres, index|
          task_array[index].create!(
            appeal_id: corres.id,
            appeal_type: "Correspondence",
            assigned_to: InboundOpsTeam.singleton
          )
        end
      end

      # Used to mock a single task to compare task sorting
      PrivacyActRequestCorrespondenceTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      PrivacyActRequestCorrespondenceTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully loads the pending tab" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      expect(page).to have_content("Correspondence that is currently assigned to non-mail team users:")
    end

    it "uses veteran details sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Veteran Details']").click
      first_vet_info = page.all("#task-link")[0].text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Veteran Details']").click
      last_vet_info = page.all("#task-link")[0].text
      # return to A-Z, compare details
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == first_vet_info)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == last_vet_info)
    end

    it "uses VA DOR sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by VA DOR']").click
      first_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by VA DOR']").click
      last_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare details
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_date)
      # return to Z-A, compare details again
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_date)
    end

    it "uses receipt date between filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      current_date = Time.zone.today
      my_date = (current_date - 3).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses days waiting sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Days Waiting']").click
      first_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Days Waiting']").click
      second_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # return to A-Z, compare details
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == first_day_amount)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == second_day_amount)
    end

    it "uses tasks sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Tasks']").click
      first_task = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Tasks']").click
      last_task = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare details
      find("[aria-label='Sort by Tasks']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_task)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Tasks']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_task)
    end

    it "uses tasks filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      all(".cf-filter-option-row")[1].click
      # find_by_id("0-CavcCorrespondenceCorrespondenceTask").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length == 5)
    end

    it "uses assigned to sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Assigned To']").click
      first_assignee = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Assigned To']").click
      last_assignee = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare details
      find("[aria-label='Sort by Assigned To']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_assignee)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Assigned To']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_assignee)
    end
  end

  context "Banner alert for approval and reject request" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }
    before :each do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      5.times do
        corres_array = (1..2).map { create(:correspondence) }
        task_array = [ReassignPackageTask, RemovePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_type: "Correspondence",
            appeal_id: corres.id,
            assigned_to: InboundOpsTeam.singleton,
            instructions: ["This was the default"],
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end
    end

    it "approve request to reassign" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find('[for="vertical-radio_approve"]').click
      find("#react-select-2-input").find(:xpath, "..").find(:xpath, "..").find(:xpath, "..").click
      find("#react-select-2-option-0").click
      find("#Review-request-button-id-1").click
      using_wait_time(30) do
        expect(page).to have_content("You have successfully reassigned a mail record for")
      end
    end

    it "deny request to reassign" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find('[for="vertical-radio_reject"]').click
      all("textarea")[0].fill_in with: "this is a rejection reason"
      find("#Review-request-button-id-1").click
      using_wait_time(30) do
        expect(page).to have_content("You have successfully rejected a package request for")
      end
    end

    it "approve request to reassign in review_package view" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find("#Review-request-button-id-2").click
      find("#button-Review-reassign-request").click
      find('[for="reassign-package_approve"]').click
      find("#react-select-4-input").find(:xpath, "..").find(:xpath, "..").find(:xpath, "..").click
      find("#react-select-4-option-0").click
      click_button("Confirm")
      using_wait_time(30) do
        expect(page).to have_content("You have successfully reassigned a mail record for")
      end
    end

    it "deny request to reassign in review_package view" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find("#Review-request-button-id-2").click
      find("#button-Review-reassign-request").click
      find('[for="reassign-package_reject"]').click
      find(".cf-form-textarea", match: :first).fill_in with: "this is a rejection reason"
      click_button("Confirm")
      using_wait_time(30) do
        expect(page).to have_content("You have successfully rejected a package request")
      end
    end

    it "approve request to remove" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[2].find("a#task-link").click
      find('[for="vertical-radio_approve"]').click
      find("#Review-request-button-id-1").click
      using_wait_time(30) do
        expect(page).to have_content("You have successfully removed a mail package for")
      end
    end

    it "deny request to remove" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[2].find("a#task-link").click
      find('[for="vertical-radio_reject"]').click
      all("textarea")[0].fill_in with: "this is a rejection reason"
      find("#Review-request-button-id-1").click
      using_wait_time(30) do
        expect(page).to have_content("You have successfully rejected a package request")
      end
    end

    it "goes to Task Package" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find("[id='Review-request-button-id-2']").click
      expect(page).to have_content("Review the mail package details below.")
    end
  end

  context "correspondence tasks completed tab testing filters date " do
    let(:current_user) { create(:inbound_ops_team_supervisor) }

    before do
      20.times do
        correspondence_root_task_completion
      end
    end

    before :each do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
    end

    it "filters date column with 'between' the date is older than today in 'from' field" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-0").click
      current_date = Time.zone.today.strftime("%m/%d/%Y")
      start_date = (Time.zone.today + 1.day).strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: current_date)
      all("div.input-container > input")[1].fill_in(with: start_date)

      expect(page).to have_button("Apply filter", disabled: true)
      expect(page).to have_content("Date completed cannot occur in the future.")
    end

    it "filters date column with 'between' the date is older than today in 'to' field" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-0").click
      current_date = Time.zone.today
      end_date = (current_date + 1).strftime("%m/%d/%Y")

      all("div.input-container > input")[1].fill_in(with: end_date)

      expect(page).to have_button("Apply filter", disabled: true)
      expect(page).to have_content("Date completed cannot occur in the future.")
    end

    it "filters date column with 'between' the date in 'to' is older than 'from' field" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-0").click
      current_date = Time.zone.today
      start_date = (current_date - 1).strftime("%m/%d/%Y")
      end_date = (current_date - 3).strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: start_date)
      all("div.input-container > input")[1].fill_in(with: end_date)

      expect(page).to have_button("Apply filter", disabled: true)
      expect(page).to have_content("To date cannot occur before from date")
    end

    it "filters date column with 'before' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"
      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-1").click
      current_date = Time.zone.today
      start_date = (current_date + 3).strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: start_date)
      expect(page).to have_button("Apply filter", disabled: true)
      expect(page).to have_content("Date completed cannot occur in the future.")
    end

    it "filters date column with 'after' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-2").click
      current_date = Time.zone.yesterday
      after_date = (current_date + 3).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: after_date)
      expect(page).to have_button("Apply filter", disabled: true)
      expect(page).to have_content("Date completed cannot occur in the future.")
    end

    it "filters date column with 'on' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=completedDateColumn&order=asc"

      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-3").click
      current_date = Time.zone.today
      on_this_date = (current_date + 1).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: on_this_date)
      expect(page).to have_button("Apply filter", disabled: true)
      expect(page).to have_content("Date completed cannot occur in the future.")
    end
  end

  context "Package document type column" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }
    let(:alt_user) { create(:user) }
    before :each do
      InboundOpsTeam.singleton.add_user(alt_user)
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      5.times do
        correspondence_array = (1..2).map { |index| create(:correspondence, nod: index == 1) }
        task_array = [ReassignPackageTask, RemovePackageTask]

        correspondence_array.each_with_index do |correspondence, index|
          rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_type: "Correspondence",
            appeal_id: correspondence.id,
            assigned_to: InboundOpsTeam.singleton,
            instructions: ["Default for type column"],
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end
    end

    it "appears on each tab of team cases" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Package Document Type")
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Package Document Type")
      visit "queue/correspondence/team?tab=correspondence_pending&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Package Document Type")
      visit "queue/correspondence/team?tab=correspondence_team_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Package Document Type")
      visit "queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Package Document Type")
    end

    it "appears on each tab of individual queue" do
      User.authenticate!(user: alt_user)
      visit "queue/correspondence/?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Package Document Type")
      visit "queue/correspondence/?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Package Document Type")
      visit "queue/correspondence/?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Package Document Type")
    end

    it "correctly sorts NOD type" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Package Document Type']").click
      first_task = find("tbody > tr:nth-child(1) > td:nth-child(3)")
      find("[aria-label='Package Document Type']").click
      second_task = find("tbody > tr:nth-child(1) > td:nth-child(3)")
      find("[aria-label='Package Document Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == first_task.text)
      find("[aria-label='Package Document Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == second_task.text)
    end

    it "correctly filters NOD type" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='packageDocTypeColumn']").click
      all(".cf-filter-option-row")[1].click
      expect(page).to_not have_content("Non-NOD")
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='packageDocTypeColumn']").click
      all(".cf-filter-option-row")[1].click
      find("[aria-label='packageDocTypeColumn. Filtering by true']").click
      all(".cf-filter-option-row")[2].click
      expect(page).to have_content("Package Document Type (2)")
      expect(page).to have_content("Viewing 1-10 of 10 total")
    end

    it "correctly uses search bar" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      fill_in "searchBar", with: "-nod"
      expect all("td", text: "Non-NOD").length == 5
    end
  end
end
