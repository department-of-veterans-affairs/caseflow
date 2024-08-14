# frozen_string_literal: true

RSpec.feature("The Correspondence Details Response Letters page") do
  include CorrespondenceHelpers

  let(:organization) { InboundOpsTeam.singleton }
  let(:bva_user) { User.authenticate!(roles: ["Mail Intake"]) }
  let(:correspondence) { create :correspondence, :with_correspondence_intake_task }

  before(:each) do
    FeatureToggle.enable!(:correspondence_queue)
    organization.add_user(bva_user)
    bva_user.reload
  end

  context "intake form shell" do
    it "Create Response letter" do
      setup_response_letters_data
      find_by_id("tasks-tabwindow-tab-2").click
      expect(page).to have_content("Response Letters")
      binding.pry
    end
  end

end
