# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
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
      expect(page).to have_current_path("/queue/correspondence")
    end
  end

  context "correspondence cases form shell" do
    let(:current_user) { create(:user) }
    let(:veteran) { create(:veteran) }

    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      @correspondence_uuid = "123456789"
      10.times do
        create(
          :correspondence,
          :with_single_doc,
          assigned_to: current_user,
          veteran_id: veteran.id,
          uuid: SecureRandom.uuid,
          va_date_of_receipt: Time.zone.local(2023, 1, 1)
        )
      end
    end
  end
end
