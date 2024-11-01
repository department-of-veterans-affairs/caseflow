# frozen_string_literal: true

feature "Saved Searches", :postgres do
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user, css_id: "REPORT USER", full_name: "Report User") }
  let(:vha_saved_searches_url) { "/decision_reviews/vha/searches" }
  let(:user_saved_search) { create(:saved_search, user: user) }
  let(:all_saved_searches) { create_list(:saved_search, 5) }

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

  context "check save search page is rendering user's searches and all searches" do
    it "When VHA admin user clicks on All Saved Searches should see all saved searches" do
      all_saved_searches
      table = page.find("tbody")
      page.find("saved-search-queue-tab-1").click

      table_row = table.first('tr[id^="table-row"]')
      expect(table_row.count).to eq(5)
      expect(table_row).to have_content(" ")
    end

    it "When VHA admin user clicks on my Saved Searches should see their saved searches" do
      user_saved_search
      table = page.find("tbody")
      page.find('saved-search-queue-tab-0').click

      table_row = table.first('tr[id^="table-row"]')
      expect(table_row.count).to eq(1)
      expect(table_row).to have_content(" ")
    end
  end
end
