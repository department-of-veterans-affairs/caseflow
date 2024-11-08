# frozen_string_literal: true

feature "Saved Searches", :postgres do
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user, css_id: "REPORT USER", full_name: "Report User") }
  let(:vha_saved_searches_url) { "/decision_reviews/vha/searches" }

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
      visit vha_saved_searches_url
    end

    context "check save search page is rendering user's searches and all searches" do
      it "When VHA admin user clicks on All Saved Searches should see all saved searches" do
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
    end
  end
end
