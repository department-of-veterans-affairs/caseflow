# frozen_string_literal: true

RSpec.feature "CAVC Dashboard", :all_dbs do
  let(:legacy_appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }
  let(:non_cavc_appeal) { create(:appeal, :direct_review_docket) }
  let(:cavc_remand) { create(:cavc_remand) }
  let(:authorized_user) { create(:user) }
  let(:unauthorized_user) { create(:user) }
  let(:occteam_organization) { OccTeam.singleton }
  let(:oaiteam_organization) { OaiTeam.singleton }

  context "user is not a member of OAI or OCC organization" do
    before { User.authenticate!(user: unauthorized_user) }

    it "user cannot see the CAVC Dashboard button on the remand appeal case details page" do
      visit "/queue/appeals/#{cavc_remand.remand_appeal.uuid}"

      expect(page).to have_text "CAVC Remand"
      expect(page).not_to have_text "CAVC Dashboard"
    end
  end

  context "OCC user cannot add issues to the cavc dashboard" do
    before do
      occteam_organization.add_user(unauthorized_user)
      User.authenticate!(user: unauthorized_user)
      occteam_organization.add_user(unauthorized_user)
    end

    it "dashboard loads as read-only if the appeal has an associated cavcRemand" do
      visit "/queue/appeals/#{cavc_remand.remand_appeal.uuid}/"
      click_button "CAVC Dashboard"
      expect(page).to have_text `CAVC appeals for #{cavc_remand.remand_appeal.veteran.name}`
      expect(page).to_not have_content(COPY::ADD_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT)
    end
  end

  context "OAI user can add issues to the cavc dashboard" do
    before do
      oaiteam_organization.add_user(authorized_user)
      User.authenticate!(user: authorized_user)
      oaiteam_organization.add_user(authorized_user)
    end

    it "dashboard loads as editable if the appeal has an associated cavcRemand" do
      visit "/queue/appeals/#{cavc_remand.remand_appeal.uuid}/"
      click_button "CAVC Dashboard"
      expect(page).to have_text `CAVC appeals for #{cavc_remand.remand_appeal.veteran.name}`
      expect(page).to have_content(COPY::ADD_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT)
    end
  end
end
