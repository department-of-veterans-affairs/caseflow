# frozen_string_literal: true

feature "Saved Searches", :postgres do
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user, css_id: "REPORT USER", full_name: "Report User") }
  let(:vha_saved_searches_url) { "/decision_reviews/vha/report/searches" }

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
end
