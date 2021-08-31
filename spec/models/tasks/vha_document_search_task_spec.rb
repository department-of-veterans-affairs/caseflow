# frozen_string_literal: true

describe VhaDocumentSearchTask, :postgres do
  let(:task) { create(:vha_document_search_task) }
  let(:camo) { VhaCamo.singleton }
  let(:user) { create(:user) }

  before { camo.add_user(user) }

  describe ".label" do
    it "uses a friendly label" do
      expect(task.class.label).to eq COPY::VHA_ASSESS_DOCUMENTATION_TASK_LABEL
    end
  end

  describe "#available_actions" do
    subject { task.available_actions(user) }

    available_actions = [
      Constants.TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.to_h,
      Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.to_h
    ]

    it { is_expected.to eq available_actions }
  end
end
