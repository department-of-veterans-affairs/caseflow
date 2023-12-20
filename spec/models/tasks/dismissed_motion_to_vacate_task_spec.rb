# frozen_string_literal: true

describe DismissedMotionToVacateTask, :postgres do
  let(:task) { create(:dismissed_motion_to_vacate_task) }

  describe ".org" do
    it "should return correct org regardless of user" do
      org = DismissedMotionToVacateTask.org(nil)
      expect(org).to eq LitigationSupport.singleton
    end
  end

  describe ".completion_contact" do
    it "should return correct completion contact" do
      contact = task.completion_contact
      expect(contact).to eq "the Litigation Support team"
    end
  end
end
