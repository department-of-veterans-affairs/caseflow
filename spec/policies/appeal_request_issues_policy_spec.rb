# frozen_string_literal: true

describe AppealRequestIssuesPolicy, :postgres do
  describe "#editable?" do
    let(:appeal) { build_stubbed(:appeal) }
    let(:user) { build_stubbed(:user) }

    subject { AppealRequestIssuesPolicy.new(user: user, appeal: appeal).editable? }

    context "when appeal has assigned attorney task assigned to user" do
      it "returns true" do
        create(:task,
               type: "AttorneyTask",
               appeal: appeal,
               assigned_to: user)

        expect(subject).to be true
      end
    end

    context "when appeal has assigned attorney task not assigned to user" do
      it "returns false" do
        create(:task,
               type: "AttorneyTask",
               appeal: appeal,
               assigned_to: build_stubbed(:user))

        expect(subject).to be false
      end
    end

    context "when appeal has in-progress judge task assigned to user" do
      it "returns true" do
        create(:task,
               :in_progress,
               type: "JudgeDecisionReviewTask",
               appeal: appeal,
               assigned_to: user)

        expect(subject).to be true
      end
    end

    context "when appeal has completed attorney task assigned to user" do
      it "returns false" do
        create(:task,
               :completed,
               type: "AttorneyTask",
               appeal: appeal,
               assigned_to: user)

        expect(subject).to be false
      end
    end

    context "when appeal has assigned task assigned to user that is neither a Judge or Attorney Task" do
      it "return false" do
        create(:task,
               type: "ColocatedTask",
               appeal: appeal,
               assigned_to: user)

        expect(subject).to be false
      end
    end

    context "when user is a member of the Case Review team, and the appeal has not
            been assigned to an attorney yet" do
      let(:user) { create(:user) }

      it "returns true" do
        CaseReview.singleton.add_user(user)
        create(:task,
               type: "ColocatedTask",
               appeal: appeal,
               assigned_to: build_stubbed(:user))

        expect(subject).to be true
      end
    end

    context "when user is a member of the Case Review team, and the appeal has
            already been assigned to an attorney" do
      let(:user) { create(:user) }
      let!(:attorney_task) do
        create(:task,
               type: "AttorneyTask",
               appeal: appeal,
               assigned_to: build_stubbed(:user))
      end
      before { CaseReview.singleton.add_user(user) }

      it { is_expected.to be false }

      context "when the attorney task has been completed and the case is not in active review" do
        let!(:attorney_task) do
          create(:task,
                 :completed,
                 type: "AttorneyTask",
                 appeal: appeal,
                 assigned_to: build_stubbed(:user))
        end

        it { is_expected.to be true }
      end
    end
  end
end
