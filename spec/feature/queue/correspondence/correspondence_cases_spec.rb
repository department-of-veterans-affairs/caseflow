# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  include CorrespondenceTaskHelpers
  # alias this to avoid the method name collision
  alias_method :create_efolderupload_task, :create_efolderupload_failed_task
  include QueueHelpers

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
        create_efolderupload_task(correspondence, parent_task, user: current_user)
      end
      # Used to mock a single task to compare task sorting
      EfolderUploadFailedTask.first.update!(type: "ReviewPackageTask")
      EfolderUploadFailedTask.first.correspondence.update!(va_date_of_receipt: Date.new(2000, 10, 10))
      EfolderUploadFailedTask.last.correspondence.update!(va_date_of_receipt: Date.new(2024, 10, 10))
    end

    it "successfully loads the in progress tab" do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Correspondence in progress")
    end

    it "uses veteran details sort correctly." do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
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
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
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
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
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
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
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
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
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
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date between filter correctly" do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
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
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2024")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[0].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end

    it "uses uses task filter correctly" do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find("label", text: "Review Package Task (1)").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end
  end
end
