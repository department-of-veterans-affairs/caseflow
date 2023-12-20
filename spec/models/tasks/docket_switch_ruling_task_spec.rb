# frozen_string_literal: true

describe DocketSwitchRulingTask, :postgres do
  let(:task_class) { DocketSwitchRulingTask }
  let(:judge) { create(:user) }
  let(:appeal) { create(:appeal) }

  describe ".additional_available_actions" do
    let(:task) { create(task_class.name.underscore.to_sym, appeal: appeal, assigned_to: judge) }

    subject { task.additional_available_actions(judge) }

    context "without docket_switch feature toggle" do
      it "returns the available_actions as defined by Task" do
        expect(subject).to eq([])
      end
    end

    context "with docket_switch feature toggle" do
      before { FeatureToggle.enable!(:docket_switch) }
      after { FeatureToggle.disable!(:docket_switch) }

      it "returns the available_actions as defined by Task" do
        expect(subject).to eq([Constants.TASK_ACTIONS.DOCKET_SWITCH_JUDGE_RULING.to_h])
      end
    end
  end
end
