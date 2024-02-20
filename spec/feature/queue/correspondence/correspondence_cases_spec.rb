# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  include CorrespondenceTaskHelpers
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
      current_date = Time.zone.today
      after_date = current_date.strftime("%m/%d/%Y")
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
end
