# frozen_string_literal: true

describe DocketSwitchGrantedTask, :postgres do
  let(:user) { create(:user) }
  let(:cotb_team) { ClerkOfTheBoard.singleton }

  before do
    cotb_team.add_user(user)
  end

  describe ".available_actions" do
    let(:attorney_task) { create(:ama_judge_decision_review_task) }

    subject { attorney_task.available_actions(user) }

    context "when the current user is not a member of the Clerk of the Board team" do
      before { allow_any_instance_of(ClerkOfTheBoard).to receive(:user_has_access?).and_return(false) }
      context "without docket_change feature toggle" do
        it "returns the correct label" do
          expect(DocketSwitchGrantedTask.new.label).to eq(
            COPY::DOCKET_SWITCH_GRANTED_TASK_LABEL
          )
        end
      end

      context "with docket_change feature toggle" do
        before { FeatureToggle.enable!(:docket_change) }
        after { FeatureToggle.disable!(:docket_change) }

        it "returns the available_actions as defined by Task" do
          expect(subject).to eq []
        end
      end
    end
  end
end
