# frozen_string_literal: true

describe NoShowHearingTask do
  let(:appeal) { FactoryBot.create(:appeal, :hearing_docket) }
  let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }

  describe ".create!" do
    it "is automatically assigned to the HearingAdmin organization" do
      expect(NoShowHearingTask.create!(appeal: appeal, parent: root_task).assigned_to).to eq(HearingAdmin.singleton)
    end
  end
end
