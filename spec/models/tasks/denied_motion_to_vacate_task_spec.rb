# frozen_string_literal: true

describe DeniedMotionToVacateTask, :postgres do
  let(:task) { create(:denied_motion_to_vacate_task) }

  describe ".org" do
    it "should return correct org regardless of user" do
      org = DeniedMotionToVacateTask.org(nil)
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
