# frozen_string_literal: true

describe JudgeTask, :all_dbs do
  let(:judge) { create(:user) }
  let(:judge2) { create(:user) }
  let(:attorney) { create(:user) }

  before do
    create(:staff, :judge_role, sdomainid: judge.css_id)
    create(:staff, :judge_role, sdomainid: judge2.css_id)
    create(:staff, :attorney_role, sdomainid: attorney.css_id)
  end

  describe "only_open_task_of_type" do
    let(:appeal) { create(:appeal) }
    let!(:first_assign_task) do
      create(:ama_judge_assign_task, assigned_to: judge, appeal: appeal)
    end
    let!(:first_review_task) do
      create(:ama_judge_decision_review_task, assigned_to: judge, appeal: appeal)
    end

    context "when one judge assign task is open for an appeal" do
      it "throws an error when a second task is created" do
        expect { create(:ama_judge_assign_task, assigned_to: judge, appeal: appeal) }.to raise_error do |error|
          expect(error).to be_a(Caseflow::Error::MultipleOpenTasksOfSameTypeError)
        end
      end
    end

    context "when one judge decision review task is open for an appeal" do
      it "throws an error when a second task is created" do
        expect { create(:ama_judge_decision_review_task, assigned_to: judge2, appeal: appeal) }.to raise_error do |err|
          expect(err).to be_a(Caseflow::Error::MultipleOpenTasksOfSameTypeError)
        end
      end
    end
  end

  describe "reassign" do
    let(:root_task) { create(:root_task) }
    let(:old_assignee) { task.assigned_to }
    let(:new_assignee) { create(:user) }
    let(:params) do
      {
        assigned_to_id: new_assignee.id,
        assigned_to_type: new_assignee.class.name,
        instructions: "instructions"
      }
    end
    subject { task.reassign(params, old_assignee) }

    context "when the task is a judge decision review task" do
      let(:task) { create(:ama_judge_decision_review_task, parent: root_task) }
      context "when the judge decision review task is reassigned successfully" do
        it "does not violate the only_open_task_of_type validation" do
          expect { subject }.to_not raise_error
        end
      end
    end

    context "when the task is a judge assign task" do
      let(:task) { create(:ama_judge_assign_task, parent: root_task) }
      context "when the judge assign task is reassigned successfully" do
        it "should not violate the only_open_task_of_type validation" do
          expect { subject }.to_not raise_error
        end
      end
    end
  end

  describe ".available_actions" do
    let(:user) { judge }
    let(:appeal) { create(:appeal, stream_type: stream_type) }
    let(:stream_type) { Constants.AMA_STREAM_TYPES.original }
    let(:subject_task) do
      create(:ama_judge_assign_task, assigned_to: judge, appeal: appeal)
    end

    subject { subject_task.available_actions_unwrapper(user) }

    context "the task is not assigned to the current user" do
      let(:user) { judge2 }
      it "should return an empty array" do
        expect(subject).to eq([])
      end
    end

    context "user is a Case Movement team member" do
      let(:user) do
        create(:user).tap { |scm_user| SpecialCaseMovementTeam.singleton.add_user(scm_user) }
      end

      context "in the assign phase" do
        it "should return the Case Management assignment actions along with attorneys" do
          expect(subject).to eq(
            [
              Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
              Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
            ].map { |action| subject_task.build_action_hash(action, user) }
          )
          assign_action_hash = subject.find { |hash| hash[:label].eql? Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.label }
          expect(assign_action_hash[:data][:options].nil?).to eq false
        end
      end

      context "in the review phase" do
        let(:subject_task) do
          create(:ama_judge_decision_review_task, assigned_to: judge, parent: create(:root_task))
        end

        it "returns the reassign action" do
          expect(subject).to eq(
            [
              Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h
            ].map { |action| subject_task.build_action_hash(action, judge) }
          )
        end
      end
    end

    context "the task is assigned to the current user" do
      context "in the assign phase" do
        it "should return the assignment action, but no attorneys" do
          expect(subject).to eq(
            [
              Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
              Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h,
              Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
              Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
            ].map { |action| subject_task.build_action_hash(action, judge) }
          )
          assign_action_hash = subject.find { |hash| hash[:label].eql? Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.label }
          expect(assign_action_hash[:data][:options].nil?).to eq true
        end

        context "the task was assigned from Quality Review" do
          let(:subject_task) { create(:ama_judge_quality_review_task, assigned_to: judge) }

          it "should return the assignment and mark complete actions" do
            expect(subject).to eq(
              [
                Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
                Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h,
                Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
                Constants.TASK_ACTIONS.JUDGE_QR_RETURN_TO_ATTORNEY.to_h,
                Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
                Constants.TASK_ACTIONS.CANCEL_TASK.to_h
              ].map { |action| subject_task.build_action_hash(action, judge) }
            )
          end
        end
      end

      context "in the review phase" do
        let(:subject_task) do
          create(:ama_judge_decision_review_task, assigned_to: judge, parent: create(:root_task))
        end

        it "returns the dispatch action" do
          expect(subject).to eq(
            [
              Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
              Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h,
              Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
              Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h,
              Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h
            ].map { |action| subject_task.build_action_hash(action, judge) }
          )
        end
        it "returns the correct dispatch action" do
          expect(subject).not_to eq(
            [
              Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
              Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h,
              Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h
            ].map { |action| subject_task.build_action_hash(action, judge) }
          )
        end

        it "returns the correct label" do
          expect(JudgeDecisionReviewTask.new.label).to eq(
            COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
          )
        end

        it "returns the correct additional actions" do
          expect(JudgeDecisionReviewTask.new(assigned_to: user).additional_available_actions(user)).to eq(
            [Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h,
             Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h]
          )
        end
      end
    end

    context "when it is a vacate type appeal" do
      let(:judge3) { create(:user) }
      let!(:user) { judge3 }
      let(:stream_type) { Constants.AMA_STREAM_TYPES.vacate }
      let!(:task) do
        create(:ama_judge_decision_review_task,
               appeal: appeal,
               assigned_to: judge3)
      end

      it "should show pulac cerullo task action" do
        expect(task.additional_available_actions(user)).to eq(
          [Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h,
           Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h,
           Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h]
        )
      end
    end
  end

  describe ".create_from_params" do
    context "creating a JudgeQualityReviewTask from a QualityReviewTask" do
      let(:judge_task) do
        create(:ama_judge_decision_review_task, parent: create(:root_task), assigned_to: judge)
      end
      let(:qr_user) { create(:user) }
      let(:qr_task) { create(:qr_task, assigned_to: qr_user, parent: judge_task) }
      let(:params) do
        { assigned_to_id: judge.id, assigned_to_type: User.name, appeal: qr_task.appeal, parent_id: qr_task.id }
      end

      subject { JudgeQualityReviewTask.create_from_params(params, qr_user) }

      before do
        QualityReview.singleton.add_user(qr_user)
      end

      it "the parent task should change to an 'on hold' status" do
        expect(qr_task.status).to eq("assigned")
        expect(subject.parent.id).to eq(qr_task.id)
        expect(subject.parent.status).to eq("on_hold")
      end
    end
  end

  describe ".create" do
    context "creating a second JudgeDecisionReviewTask" do
      let(:root_task) { create(:root_task) }
      let!(:jdrt) do
        create(:ama_judge_decision_review_task, appeal: root_task.appeal, parent: root_task, assigned_to: judge)
      end

      subject { JudgeDecisionReviewTask.create!(appeal: root_task.appeal, parent: root_task, assigned_to: judge) }

      Task.open_statuses.each do |o_status|
        context "when an open (#{o_status}) JudgeDecisionReviewTask already exists" do
          it "should fail creation of second JudgeDecisionReviewTask" do
            expect(root_task.appeal.tasks.count).to eq(2), root_task.appeal.tasks.to_a.to_s
            jdrt.update(status: o_status)
            expect { subject }.to raise_error(Caseflow::Error::MultipleOpenTasksOfSameTypeError)
            expect(root_task.appeal.tasks.count).to eq(2), root_task.appeal.tasks.to_a.to_s
          end
        end
      end

      Task.closed_statuses.each do |c_status|
        context "when a closed (#{c_status}) JudgeDecisionReviewTask exists" do
          it "should create new active JudgeDecisionReviewTask" do
            jdrt.update(status: c_status)
            expect(root_task.appeal.tasks.count).to eq(2), root_task.appeal.tasks.to_a.to_s
            expect { subject }.to_not raise_error
            expect(root_task.appeal.tasks.count).to eq(3), root_task.appeal.tasks.to_a.to_s
            expect(root_task.appeal.tasks.of_type(:JudgeDecisionReviewTask).count).to eq(2)
          end
        end
      end
    end
  end

  describe ".update_from_params" do
    context "updating a JudgeQualityReviewTask" do
      let(:existing_instructions) { "existing instructions" }
      let(:existing_status) { :assigned }
      let!(:jqr_task) do
        create(
          :ama_judge_quality_review_task,
          assigned_to: judge,
          status: existing_status,
          instructions: [existing_instructions]
        )
      end
      let(:params) { nil }

      subject { jqr_task.update_from_params(params, judge) }

      context "update includes instruction text" do
        let(:new_instructions) { "new instructions" }
        let(:params) { { instructions: [new_instructions] }.with_indifferent_access }

        it "merges instruction text" do
          subject
          expect(jqr_task.reload.instructions).to eq([existing_instructions, new_instructions])
        end
      end

      context "update has a nil status" do
        let(:params) { { status: nil } }

        it "doesn't change the task's status" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
          expect(jqr_task.reload.status).to eq(existing_status.to_s)
        end
      end
    end
  end

  describe ".previous_task" do
    let(:parent) { create(:ama_judge_decision_review_task, assigned_to: judge) }
    let!(:child) do
      create(
        :ama_attorney_task,
        :completed,
        assigned_to: attorney,
        assigned_by: judge,
        parent: parent
      )
    end

    subject { parent.previous_task }

    context "when there is only one child attorney task" do
      it "returns the only child" do
        expect(subject).to eq(child)
      end
    end

    context "when there are two child attorney tasks that have been assigned" do
      let!(:older_child_task) do
        child.tap do |t|
          t.assigned_at = Time.zone.now - 6.days
          t.save!
        end
      end

      let!(:newer_child_task) do
        child.tap do |t|
          t.assigned_at = Time.zone.now - 1.day
          t.save!
        end
      end

      it "should return the most recently assigned attorney task" do
        expect(subject).to eq(newer_child_task)
      end
    end
  end

  describe "when child task completed" do
    let(:judge_task) { create(:ama_judge_assign_task) }

    subject { child_task.update!(status: Constants.TASK_STATUSES.completed) }

    context "when child task is an attorney task" do
      let(:child_task) do
        create(
          :ama_attorney_task,
          assigned_by: judge,
          assigned_to: attorney,
          parent: judge_task
        )
      end

      before { Timecop.freeze(Time.zone.local(2019, 9, 2)) }

      it "changes the judge task type to decision review and sends an error to sentry" do
        expect(judge_task.type).to eq(JudgeAssignTask.name)
        expect(Raven).to receive(:capture_message).with(
          "Still changing JudgeAssignTask type to JudgeDecisionReviewTask."\
           "See: https://github.com/department-of-veterans-affairs/caseflow/pull/11140#discussion_r295487938",
          extra: { application: "tasks" }
        )
        subject
        expect(Task.find(judge_task.id).type).to eq(JudgeDecisionReviewTask.name)
      end
    end

    context "when child task is an VLJ support staff admin action" do
      let(:child_task) { create(:colocated_task, assigned_by: judge, parent: judge_task, assigned_to: create(:user)) }

      it "does not change the judge task type" do
        expect(judge_task.type).to eq(JudgeAssignTask.name)
        subject
        expect(Task.find(judge_task.id).type).to eq(JudgeAssignTask.name)
      end
    end
  end
end
