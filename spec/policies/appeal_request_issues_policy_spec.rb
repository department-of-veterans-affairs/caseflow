# frozen_string_literal: true

describe AppealRequestIssuesPolicy do
  describe "#editable?" do
    let(:appeal) { build_stubbed(:appeal) }
    let(:user) { build_stubbed(:user) }

    subject { AppealRequestIssuesPolicy.new(user: user, appeal: appeal).editable? }

    context "when appeal has assigned attorney task assigned to user" do
      it "returns true" do
        create(:task,
               type: "AttorneyTask",
               appeal: appeal,
               assigned_to: user,
               status: Constants.TASK_STATUSES.assigned)

        expect(subject).to be true
      end
    end

    context "when appeal has assigned attorney task not assigned to user" do
      it "returns false" do
        create(:task,
               type: "AttorneyTask",
               appeal: appeal,
               assigned_to: build_stubbed(:user),
               status: Constants.TASK_STATUSES.assigned)

        expect(subject).to be false
      end
    end

    context "when appeal has in-progress judge task assigned to user" do
      it "returns true" do
        create(:task,
               type: "JudgeDecisionReviewTask",
               appeal: appeal,
               assigned_to: user,
               status: Constants.TASK_STATUSES.in_progress)

        expect(subject).to be true
      end
    end

    context "when appeal has completed attorney task assigned to user" do
      it "returns false" do
        create(:task,
               type: "AttorneyTask",
               appeal: appeal,
               assigned_to: user,
               status: Constants.TASK_STATUSES.completed)

        expect(subject).to be false
      end
    end

    context "when appeal has assigned task assigned to user that is neither a Judge or Attorney Task" do
      it "return false" do
        create(:task,
               type: "ColocatedTask",
               appeal: appeal,
               assigned_to: user,
               status: Constants.TASK_STATUSES.assigned)

        expect(subject).to be false
      end
    end

    context "when user is a member of the Case Review team, regardless of the appeal's tasks" do
      let(:user) { create(:user) }

      it "returns true" do
        OrganizationsUser.add_user_to_organization(user, BvaIntake.singleton)
        create(:task,
               type: "ColocatedTask",
               appeal: appeal,
               assigned_to: build_stubbed(:user),
               status: Constants.TASK_STATUSES.assigned)

        expect(subject).to be true
      end
    end
  end
end
