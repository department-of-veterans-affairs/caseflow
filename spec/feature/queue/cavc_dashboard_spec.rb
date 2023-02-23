# frozen_string_literal: true

RSpec.feature "CAVC Dashboard", :all_dbs do
  let(:legacy_appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }
  let(:non_cavc_appeal) { create(:appeal, :direct_review_docket) }
  let(:cavc_appeal) { create(:appeal, :direct_review_docket, :type_cavc_remand) }
  let(:authorized_user) { create(:user) }
  let(:unauthorized_user) { create(:user) }
  let(:occteam_organization) { OccTeam.singleton }
  let(:oaiteam_organization) { OaiTeam.singleton }

  context "user is not a member of OAI or OCC organization" do
    before { User.authenticate!(user: unauthorized_user) }

    it "dashboard redirects to case details page" do
      visit "/queue/appeals/#{cavc_appeal.uuid}/cavc_dashboard"
      expect(page).to have_text cavc_appeal.veteran.name.to_s
      expect(page).to have_current_path "/queue/appeals/#{cavc_appeal.uuid}"
    end
  end

  context "user is a member of OAI or OCC organizations" do
    before do
      User.authenticate!(user: authorized_user)
      occteam_organization.add_user(authorized_user)
      oaiteam_organization.add_user(authorized_user)
    end

    it "dashboard redirects if the appeal is a Legacy Appeal" do
      visit "/queue/appeals/#{legacy_appeal.vacols_id}/cavc_dashboard"
      expect(page).to have_text legacy_appeal.veteran.name.to_s
      expect(page).to have_current_path "/queue/appeals/#{legacy_appeal.vacols_id}"
    end

    it "dashboard redirects if the appeal does not have an associated cavcRemand" do
      visit "/queue/appeals/#{non_cavc_appeal.uuid}/cavc_dashboard"
      expect(page).to have_text non_cavc_appeal.veteran.name.to_s
      expect(page).to have_current_path "/queue/appeals/#{non_cavc_appeal.uuid}"
    end

    # this test will need to be updated once CavcDashboard component is built
    it "dashboard loads if the appeal has an associated cavcRemand" do
      visit "/queue/appeals/#{cavc_appeal.uuid}/cavc_dashboard"
      expect(page).to have_text "CAVC appeals for #{cavc_appeal.veteran.name}"
    end
  end

  context "unauthorized user cannot add issues to the cavc dashboard" do
    before do
      occteam_organization.add_user(unauthorized_user)
      User.authenticate!(user: unauthorized_user)
      occteam_organization.add_user(unauthorized_user)
    end

    it "dashboard loads as read-only if the appeal has an associated cavcRemand" do
      visit "/queue/appeals/#{cavc_appeal.uuid}/cavc_dashboard"
      expect(page).to_not have_content(COPY::ADD_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT)
    end
  end

  context "authorized user can add issues to the cavc dashboard" do
    before do
      oaiteam_organization.add_user(authorized_user)
      User.authenticate!(user: authorized_user)
      oaiteam_organization.add_user(authorized_user)
    end

    it "dashboard loads as editable if the appeal has an associated cavcRemand" do
      visit "/queue/appeals/#{cavc_appeal.uuid}/cavc_dashboard"
      expect(page).to have_content(COPY::ADD_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT)
    end
  end
end
