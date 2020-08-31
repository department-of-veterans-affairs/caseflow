# frozen_string_literal: true

# Shared examples for both SpecialCaseMovementTask and BlockedSpecialCaseMovementTask

shared_examples "successful creation" do
  it "should create the SCM task and JudgeAssign task" do
    expect { subject }.not_to raise_error
    scm_task =  appeal.tasks.where(type: described_class.name).first
    expect(scm_task.status).to eq(Constants.TASK_STATUSES.completed)
    judge_task = appeal.tasks.open.where(type: JudgeAssignTask.name).first
    expect(judge_task.status).to eq(Constants.TASK_STATUSES.assigned)
  end
end

shared_examples "appeal has a nonblocking mail task" do
  before do
    create(:aod_motion_mail_task,
           appeal: appeal,
           parent: appeal.root_task)
  end
  it_behaves_like "successful creation"
  it "still has the open mail task" do
    aod_mail_task = AodMotionMailTask.where(appeal: appeal).first
    expect(aod_mail_task.open?).to eq(true)
    expect { subject }.not_to raise_error
    expect(aod_mail_task.reload.open?).to eq(true)
  end
end

shared_examples "wrong parent task type provided" do
  context "with the evidence window task as parent" do
    let(:evidence_window_task) { appeal.tasks.open.where(type: EvidenceSubmissionWindowTask.name).first }

    subject do
      described_class.create!(appeal: appeal,
                              assigned_to: cm_user,
                              assigned_by: cm_user,
                              parent: evidence_window_task)
    end

    it "should error with wrong parent type" do
      expect { subject }.to raise_error(Caseflow::Error::InvalidParentTask)
    end
  end
end

shared_examples "appeal past distribution" do
  context "appeal at the judge already" do
    let(:appeal) do
      create(:appeal,
             :assigned_to_judge,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end
    let(:dist_task) { appeal.tasks.where(type: DistributionTask.name).first }

    subject do
      described_class.create!(appeal: appeal,
                              assigned_to: cm_user,
                              assigned_by: cm_user,
                              parent: dist_task)
    end

    it "should error with appeal not distributable" do
      expect { subject }.to raise_error(expected_error)
    end
  end
end

shared_examples "non Case Movement user provided" do
  context "with a non-CaseMovement user" do
    let(:user) { create(:user) }
    let(:appeal) do
      create(:appeal,
             :with_post_intake_tasks,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end
    let(:dist_task) { appeal.tasks.active.where(type: DistributionTask.name).first }

    subject do
      described_class.create!(appeal: appeal,
                              assigned_to: user,
                              assigned_by: user,
                              parent: dist_task)
    end

    it "should error with user error" do
      expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
    end
  end
end
