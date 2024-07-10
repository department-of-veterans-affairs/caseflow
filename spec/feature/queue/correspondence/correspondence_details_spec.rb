# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers

  let(:veteran) { create(:veteran, first_name: "John", last_name: "Testingman", file_number: "8675309") }
  let!(:correspondence) {
    create(:correspondence,
           :with_correspondence_intake_task,
           assigned_to: current_user,
           veteran_id: veteran.id,
           uuid: SecureRandom.uuid,
           va_date_of_receipt: Time.zone.local(2023, 1, 1))
  }

  context "correspondence details" do
    before :each do
      setup_access
      @correspondence = correspondence
    end

    it "properly loads the details page" do
      visit "/queue/correspondence/#{correspondence.uuid}/correspondence_details"

      binding.pry
      # Veteran Details
      expect(page).to have_content("8675309")
      expect(page).to have_content("John Testingman")

      # View all correspondence link
      expect(page).to have_link("View all correspondence")

      # Record status
      expect(page).to have_content("Record status: Pending")

      # Tabs
      expect(page).to have_content("Correspondence and Appeal Tasks")
      expect(page).to have_content("Package Details")
      expect(page).to have_content("Response Letters")
      expect(page).to have_content("Associated Prior Mail")
    end
  end
end
