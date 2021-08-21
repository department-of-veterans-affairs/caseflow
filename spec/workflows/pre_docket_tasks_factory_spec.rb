# frozen_string_literal: true

describe PreDocketTasksFactory, :postgres do
  context "PreDocket Appeals" do
    before do
      bva_intake.add_user(bva_intake_user)
      camo.add_user(camo_user)
    end

    let(:bva_intake) { BvaIntake.singleton }
    let(:bva_intake_user) { create(:intake_user) }
    let(:camo) { VhaCamo.singleton }
    let(:camo_user) { create(:user) }

    let(:appeal) { create(:appeal, intake: create(:intake, user: bva_intake_user)) }

    subject { PreDocketTasksFactory.new(appeal).call }

    it "creates a PreDocket Appeal in an on_hold status" do
      expect(PreDocketTask.all.count).to eq 0

      subject

      expect(PreDocketTask.all.count).to eq 1
      expect(PreDocketTask.first.appeal).to eq appeal
      expect(PreDocketTask.first.assigned_to).to eq BvaIntake.singleton
      expect(PreDocketTask.first.parent.is_a?(RootTask)).to eq true
      expect(PreDocketTask.first.status).to eq Constants.TASK_STATUSES.on_hold
    end
  end
end
