# frozen_string_literal: true

RSpec.feature("Search Bar for Correspondence") do
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
      expect(page).to have_current_path(
        "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      )
    end
  end

  context "correspondence assigned tab - locate the search bar" do
    let(:current_user) { create(:user) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      20.times do
        create_correspondence_review
      end
      1.times do
        update_correspondence_for_review
      end
      FeatureToggle.enable!(:correspondence_queue)
    end

    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      FeatureToggle.enable!(:user_queue_pagination)
    end

    it "successfully opens the assigned tab, finds the search box, and enters data there." do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Filter table by any of its columns")
      expect(find("#searchBar")).to match_xpath("//input[@placeholder='Type to filter...']")
      veteran = Veteran.first
      find_by_id("searchBar").fill_in with: veteran.last_name
      search_value = find("tbody > tr:nth-child(1) > td:nth-child(1)").text
      expect(search_value.include?(veteran.last_name))
    end

    it "should display the search bar with text even we shift to other tabs " do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Filter table by any of its columns")
      expect(find("#searchBar")).to match_xpath("//input[@placeholder='Type to filter...']")
      find("#searchBar", wait: 5)
      veteran = Veteran.first
      last_name = veteran.last_name.gsub("'", "\\\\'")
      page.execute_script("document.getElementById('searchBar').focus();")
      page.execute_script("document.getElementById('searchBar').value = '#{last_name}'")
      find_by_id("tasks-tabwindow-tab-1").click
      page.execute_script("document.getElementById('searchBar').focus();")
      page.execute_script("document.getElementById('searchBar').value = '#{last_name}'")
      expect(find_by_id("searchBar").value).to eq veteran.last_name
    end

    it "Should display Only search results even when we hit pagination " do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Filter table by any of its columns")
      expect(find("#searchBar")).to match_xpath("//input[@placeholder='Type to filter...']")
      veteran = Veteran.first
      last_name = veteran.last_name.gsub("'", "\\\\'")
      page.execute_script("document.getElementById('searchBar').focus();")
      page.execute_script("document.getElementById('searchBar').value = '#{last_name}'")
      expect(page).to have_button("Next")
      expect(page).not_to have_button("Previous")
      click_button("Next", match: :first)
      expect(page).not_to have_button("Next")
      click_button("Previous", match: :first)
      search_value = find("tbody > tr:nth-child(1) > td:nth-child(1)").text
      expect(search_value.include?(veteran.last_name))
    end

    it "Verify the user can clear the search bar by clicking the 'x' in the search bar" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Filter table by any of its columns")
      expect(find("#searchBar")).to match_xpath("//input[@placeholder='Type to filter...']")
      veteran = Veteran.first
      last_name = veteran.last_name.gsub("'", "\\\\'")
      last_name.chars.each do |char|
        find("#searchBar").send_keys(char)
      end
      search_value = find("tbody > tr:nth-child(1) > td:nth-child(1)").text
      expect(search_value.include?(veteran.last_name))
      find("#button-clear-search", visible: true, wait: 5)
      find_by_id("button-clear-search").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(1)").length == 1)
    end

    it "Verify the user can have search results sorted by veteran details." do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"

      expect(page).to have_content("Filter table by any of its columns")
      expect(find("#searchBar")).to match_xpath("//input[@placeholder='Type to filter...']")

      # Find Zzzane and get details
      page.execute_script("document.getElementById('searchBar').focus();")
      page.execute_script("document.getElementById('searchBar').value = 'Zzzane'")
      first("[aria-label='Page 2']").click

      # Return to first page, should not exist
      first("[aria-label='Page 1']").click
      expect(page).to have_no_content("Zzzans")

      # Sort A-Z, should result in no results
      sort_icon = find("[aria-label='Sort by Veteran Details']")
      sort_icon.click
      expect(page).to have_content("Zzzans")

      # Sort Z-A, should return details from Zzzane
      sort_icon = find("[aria-label='Sort by Veteran Details']")
      sort_icon.click
      only_vet_info = page.all("#task-link")[0].text
      expect(page.all("#task-link")[0].text).to eq(only_vet_info)
    end

    it "Verify the user can have search results filtered by receipt date on filter correctly" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      veteran = Veteran.first
      find_by_id("searchBar").fill_in with: veteran.last_name
      search_value = find("tbody > tr:nth-child(1) > td:nth-child(1)").text
      expect(search_value.include?(veteran.last_name))
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(
        with: @review_correspondence.va_date_of_receipt.strftime("%m/%d/%Y")
      )
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end
  end

  # Tested on Correspondence Cases page
  context "correspondence paginationg search testing" do
    let(:current_user) { create(:inbound_ops_team_supervisor) }
    before :each do
      InboundOpsTeam.singleton.add_user(current_user)
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    before do
      25.times do
        create_correspondence_review
      end
      1.times do
        update_correspondence_for_review
      end
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "should display the search bar with text even when switching pages in pagination" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      expect(page).to have_content("Filter table by any of its columns")
      veteran = Veteran.first
      last_name = veteran.last_name.gsub("'", "\\\\'")
      page.execute_script("document.getElementById('searchBar').focus();")
      page.execute_script("document.getElementById('searchBar').value = '#{last_name}'")
      first("[aria-label='Page 2']").click
      expect(find_by_id("searchBar").value).to eq veteran.last_name
    end

    it "should display the correct results with pagination and filtering" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      find_by_id("searchBar").fill_in with: "Zzzans"
      first("[aria-label='Page 2']").click
      only_vet_info = page.all("#task-link")[0].text
      expect(page.all("#task-link")[0].text == only_vet_info)
      # put page in the sorted Z-A state (filtering changes page Zzzane Should exist on)
      find("[aria-label='Sort by Veteran Details']").click
      first("[aria-label='Page 1']").click
      expect(page.all("#task-link")[0].text == only_vet_info)
      # check if first result is the last vet
    end

    it "should be able to search by different columns" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned"
      # searches by days waiting
      find_by_id("searchBar").fill_in with: "42"
      first("[aria-label='Page 2']").click
      only_vet_info = page.all("#task-link")[0].text
      expect(page.all("#task-link")[0].text == only_vet_info)
      # put page in the sorted Z-A state (filtering changes page Zzzane Should exist on)
      find("[aria-label='Sort by Veteran Details']").click
      first("[aria-label='Page 1']").click
      expect(page.all("#task-link")[0].text == only_vet_info)
      # check if first result is the last vet
    end
  end
end
