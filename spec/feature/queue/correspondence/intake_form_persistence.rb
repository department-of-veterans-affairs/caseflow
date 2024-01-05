# frozen_string_literal: true

RSpec.feature("Persistence of the intake correspondence page") do
  let(:veteran) { create(:veteran, last_name: "Smith", file_number: "12345678") }
  let(:correspondence) { create(:correspondence, veteran_id: veteran.id, uuid: SecureRandom.uuid) }
  let(:current_user) { create(:intake_user) }

  subject(:visit_intake_page) { visit queue_correspondence_intake_path(correspondence_uuid: correspondence.uuid) }

  before do
    FeatureToggle.enable!(:correspondence_queue)
    MailTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
  end

  context "step 1" do
    it "creates a correspondence_intake record on page load" do
      expect { visit_intake_page }.to change(CorrespondenceIntake, :count).by(1)

      expect(CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence).current_step).to eq(1)
      expect(CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence).redux_store).not_to be_nil
    end
  end

  context "step 2" do
    it "updates the correspondence_intake record when visiting step 2" do
      visit_intake_page
      click_button("Continue")

      expect(page).to have_content("Continue")

      expect(CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence).current_step).to eq(2)
      expect(CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence).redux_store).not_to be_nil
    end
  end

  context "step 3" do
    it "updates the correspondence_intake record when visiting step 3" do
      visit_intake_page
      click_button("Continue")
      click_button("Continue")

      expect(page).to have_content("Submit")

      expect(CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence).current_step).to eq(3)
      expect(CorrespondenceIntake.find_by(user: current_user, correspondence: correspondence).redux_store).not_to be_nil
    end
  end
end
