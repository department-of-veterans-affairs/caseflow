# frozen_string_literal: true

RSpec.feature("Persistence of the intake correspondence page") do
  include CorrespondenceHelpers
  let(:current_user) { create(:intake_user) }

  before do
    FeatureToggle.enable!(:correspondence_queue)
    InboundOpsTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
    # CorrespondenceIntakeTask.create_from_params(correspondence&.root_task, current_user)
  end

  context "step 1" do
    # current behavior is that the CorrespondenceIntake is created on step 2 of the form
    # unskip this test when the workflow is updated.
    xit "creates a correspondence_intake record on page load" do
      expect { visit_intake_form_with_correspondence_load }.to change(CorrespondenceIntake, :count).by(1)

      expect(CorrespondenceIntake.find_by(task: correspondence&.open_intake_task)).to eq(1)
      expect(CorrespondenceIntake.find_by(task: correspondence&.open_intake_task).redux_store).not_to be_nil
    end
  end

  context "step 2" do
    it "updates the correspondence_intake record when visiting step 2" do
      visit_intake_form_step_2_with_appeals
      correspondence = Correspondence.first
      expect(page).to have_content("Continue")

      expect(CorrespondenceIntake.find_by(task: correspondence&.open_intake_task).current_step).to eq(2)
      expect(CorrespondenceIntake.find_by(task: correspondence&.open_intake_task).redux_store).not_to be_nil
    end
  end

  context "step 3" do
    it "updates the correspondence_intake record when visiting step 3" do
      visit_intake_form_step_2_with_appeals
      correspondence = Correspondence.first

      click_button("Continue")

      expect(page).to have_content("Submit")

      expect(CorrespondenceIntake.find_by(task: correspondence&.open_intake_task).current_step).to eq(3)
      expect(CorrespondenceIntake.find_by(task: correspondence&.open_intake_task).redux_store).not_to be_nil
    end
  end
end
