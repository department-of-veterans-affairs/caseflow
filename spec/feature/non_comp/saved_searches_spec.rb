# frozen_string_literal: true

feature "Saved Searches", :postgres do
  include DownloadHelpers
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user, css_id: "REPORT USER", full_name: "Report User") }
  let(:vha_saved_searches_url) { "/decision_reviews/vha/searches" }

  let(:vha_decision_review_url) { "/decision_reviews/vha/report" }

  before do
    User.stub = user
    non_comp_org.add_user(user)
    OrganizationsUser.make_user_admin(user, non_comp_org)
    visit vha_saved_searches_url
  end

  it "admin user" do
    step "saved searches should be accessable to VHA Admin user" do
      expect(page).to have_content("Saved Searches")
    end
    step "can navigate back to report page" do
      click_link "Back to Generate task report"
      expect(current_url).to include("/decision_reviews/vha/report")
      expect(current_url).not_to include("searches")
    end
  end

  describe "checking saved search tables" do
    let!(:user_saved_search) { create(:saved_search, user: user) }
    let!(:all_saved_searches) { create_list(:saved_search, 5) }

    before do
      user_saved_search
      all_saved_searches
      visit vha_saved_searches_url
    end

    context "check save search page is rendering user's searches and all searches" do
      it "When VHA admin user clicks on All Saved Searches should see all saved searches" do
        visit vha_saved_searches_url if page.has_text?("Something went wrong.")

        page.find("button", text: "All saved searches").click
        table = page.find("tbody")

        expect(page).to have_text("Viewing 1-6 of 6 total")
        expect(table).to have_selector("tr", count: 6)
      end

      it "When VHA admin user clicks on my Saved Searches should see their saved searches" do
        page.find("button", text: "My saved searches").click
        table = page.find("tbody")

        expect(page).to have_text("Viewing 1-1 of 1 total")
        expect(table).to have_selector("tr", count: 1)
      end

      it "should have delete button that is disabled." do
        delete_buttom = find("button", text: "Delete")
        expect(delete_buttom[:disabled]).to eq "true"
      end

      it "should have delete button that will be enabled after radio button is selected." do
        select_row_radio = page.find(".cf-form-radio-option")
        select_row_radio.click

        delete_buttom = find("button", text: "Delete")
        expect(delete_buttom[:disabled]).to eq "false"
      end

      it "should open delete modal and deleting button should remove the saved search" do
        select_row_radio = page.find(".cf-form-radio-option")
        select_row_radio.click

        find("button", text: "Delete").click

        check_delete_modal(user_saved_search.name)

        expect(page).to have_content("You have successfully deleted #{user_saved_search.name}")
        expect(page).to have_text("Viewing 0-0 of 0 total")
      end
    end
  end

  context "admin user should be able to save search" do
    before do
      visit vha_decision_review_url
    end

    it "should be able to  save user searches" do
      step "open Save search modal" do
        expect(page).to have_button("Save search", disabled: true)
        click_dropdown(text: "Status")

        expect(page).to have_button("Save search")

        click_button "Save search"

        expect(page).to have_text("Save your search")
        expect(page).to have_text("Search Parameters")
      end

      step "fill required field" do
        expect(page).to have_button("Save search", disabled: true)

        fill_in "Name this search (Max 50 characters)", with: "My first Search"
        expect(page).to have_button("Save search", disabled: false)
      end

      step "fill description field and click save search" do
        fill_in "Description of search (Max 100 characters)", with: "This is the search description"

        within ".cf-modal-body" do
          click_button "Save search"
        end
      end

      step "verify success alert" do
        expect(current_url).to include("/decision_reviews/vha/report")
        expect(page).to have_text("My first Search has been saved.")
        expect(page).to have_text("To view your saved searches, click on the \"View saved searches\" button.")
      end
    end
  end

  context "admin user should see limited reach modal if user saved search is 10 or more" do
    before do
      User.stub = user
      non_comp_org.add_user(user)
      OrganizationsUser.make_user_admin(user, non_comp_org)
      user_searches
      visit vha_decision_review_url
      click_dropdown(text: "Status")
    end
    let(:user_searches) { create_list(:saved_search, 10, user: user) }

    it "should be able to delete the selected saved search from limit reached modal" do
      expect(page).to have_button("Save search")

      click_button "Save search"

      expect(page).to have_content(COPY::SAVE_LIMIT_REACH_TITLE)
      expect(page).to have_content(COPY::SAVE_LIMIT_REACH_MESSAGE)
      expect(page).to have_button("View saved searches")

      search_name = ""

      within ".cf-modal-body" do
        radio_choices = page.all(".cf-form-radio-option > label")
        expect(radio_choices.count).to eq 10
        radio_choices[0].click
        search_name = radio_choices[0].text
        delete_button = find("button", text: "Delete")
        expect(delete_button[:disabled]).to eq "false"
        delete_button.click
      end
      check_delete_modal(search_name)
      expect(page).to have_content("You have successfully deleted #{search_name}")
      expect(page).to have_text("Save your search")
      expect(page).to have_text("Search Parameters")
    end
  end

  def check_delete_modal(search_name)
    within page.find("#delete-search-modal") do
      expect(page).to have_content(COPY::DELETE_SEARCH_TITLE)
      expect(page).to have_text(COPY::DELETE_SEARCH_DESCRIPTION)
      expect(page).to have_text(search_name)
      find("button", text: "Delete").click
    end
  end

  describe "checking saved search tables" do
    let!(:user_search) { create(:saved_search, user: user) }

    before do
      User.stub = user
      non_comp_org.add_user(user)
      OrganizationsUser.make_user_admin(user, non_comp_org)
      user_search
      visit vha_saved_searches_url
    end

    context "admin user should select saved search and apply" do
      it "should navigate to reports page with loaded form data, generate report and clear" do
        page.find("button", text: "My saved searches").click

        expect(page).to have_text("Viewing 1-1 of 1 total")
        table_wrapper = page.find(".cf-table-wrapper")

        radio_choices = page.all(".cf-form-radio-option")
        radio_choices[0].click
        expect(table_wrapper).to have_content(user_search.name.to_s)

        click_button "Apply"

        expect(current_url).to include("/decision_reviews/vha/report")
        expect(page).to have_content("Event / Action")

        expect(page).to have_content("Timing specifications")
        expect(page).to have_content("Days Waiting")
        expect(page).to have_content("Less than")

        expect(page).to have_content("Decision Review Type")
        expect(page).to have_content("Higher-Level Reviews")
        expect(page).to have_content("Supplemental Claims")

        expect(page).to have_content("Issue Disposition")
        expect(page).to have_content("Dismissed")
        expect(page).to have_content("Denied")

        expect(page).to have_content("Personnel")
        expect(page).to have_content("Alex CAMOAdmin Camo")

        expect(page).to have_content("Issue Type")
        expect(page).to have_content("Caregiver | Eligibility")

        expect(page).to have_content("Camp Lejune Family Member")
        expect(page).to have_content("Caregiver | Revocation/Discharge")
        expect(page).to have_content("CHAMPVA")

        click_button "Generate task report"
        csv_file = download_csv
        expect(csv_file).to_not eq(nil)

        click_button "Clear filters"

        expect(page).to have_button("Generate task report", disabled: true)
        expect(page).to have_button("Clear filters", disabled: true)
        expect(page).to have_button("Save search", disabled: true)
      end
    end
  end

  def latest_download
    downloads.max_by { |file| File.mtime(file) }
  end

  def download_csv
    wait_for_download
    CSV.read(latest_download)
  end
end
