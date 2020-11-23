# frozen_string_literal: true

describe DocketSwitchDeniedTask, :postgres do
  let(:cotb_team) { ClerkOfTheBoard.singleton }
  let(:root_task) { create(:root_task) }
  let(:task_class) { DocketSwitchDeniedTask }
  let(:judge) { create(:user, :with_vacols_judge_record, full_name: "Judge the First", css_id: "JUDGE_1") }

  let(:attorney) { create(:user, :with_vacols_attorney_record) }

  let(:task_actions) do
    [Constants.TASK_ACTIONS.REVIEW_DECISION_DRAFT.to_h,
     Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
     Constants.TASK_ACTIONS.CANCEL_AND_RETURN_TASK.to_h]
  end

  before do
    cotb_team.add_user(attorney)
  end

  describe ".available_actions" do
    let(:attonery_task) do
      task_class.create!(
        appeal: root_task.appeal,
        parent_id: root_task.id,
        assigned_to: attorney,
        assigned_by: judge
      )
    end

    subject { attonery_task.available_actions(attorney) }

    context "when the current user is not a member of the Clerk of the Board team" do
      before { allow_any_instance_of(ClerkOfTheBoard).to receive(:user_has_access?).and_return(false) }
      context "without docket_switch feature toggle" do
        it "returns the correct label" do
          expect(DocketSwitchDeniedTask.new.label).to eq(
            COPY::DOCKET_SWITCH_DENIED_TASK_LABEL
          )
        end
      end

      context "with docket_switch feature toggle" do
        before { FeatureToggle.enable!(:docket_switch) }
        after { FeatureToggle.disable!(:docket_switch) }

        it "returns the available_actions as defined by Task" do
          expect(subject).to eq(task_actions)
        end
      end
    end

    context "when the current user is a member of the Clerk of the Board team" do
      context "without docket_switch feature toggle" do
        it "returns the available_actions as defined by Task" do
          expect(subject).to eq(task_actions)
        end
      end

      context "with docket_switch feature toggle" do
        before { FeatureToggle.enable!(:docket_switch) }
        after { FeatureToggle.disable!(:docket_switch) }

        it "returns the available_actions as defined by Task" do
          expect(subject).to eq(task_actions + [Constants.TASK_ACTIONS.DOCKET_SWITCH_DENIED.to_h])
        end
      end
    end
  end
end
