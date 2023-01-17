# frozen_string_literal: true

RSpec.feature "CAVC Dashboard", :all_dbs do
  let(:non_cavc_appeal) { create(:appeal, :direct_review_docket) }
  let(:cavc_appeal) { create(:appeal, :direct_review_docket, :type_cavc_remand) }
  let(:authorized_user) { create(:user, :oai_user) }

  context "user has OAI role" do
    before do
      User.authenticate!(user: authorized_user)
    end

    it "dashboard redirects if the appeal does not have an associated cavcRemand" do
      visit "/queue/appeals/#{non_cavc_appeal.uuid}/cavc_dashboard"
      expect(page).to have_text non_cavc_appeal.veteran.name.to_s
      expect(page).to have_current_path "/queue/appeals/#{non_cavc_appeal.uuid}"
    end

    # this test will need to be updated once CavcDashboard component is built
    it "dashboard loads if the appeal has an associated cavcRemand" do
      visit "/queue/appeals/#{cavc_appeal.uuid}/cavc_dashboard"
      expect(page).to have_text cavc_appeal.uuid.to_s
    end
  end
end
