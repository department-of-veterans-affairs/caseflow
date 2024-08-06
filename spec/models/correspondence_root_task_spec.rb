# frozen_string_literal: true

describe CorrespondenceRootTask, :all_dbs do
  let!(:user) { create(:correspondence_auto_assignable_user) }
  let!(:veteran) { create(:veteran) }

  before do
    User.authenticate!(user: user)
    FeatureToggle.enable!(:correspondence_queue)
  end

  def tasks_not_related_to_an_appeal
    [
      CavcCorrespondenceCorrespondenceTask,
      CongressionalInterestCorrespondenceTask,
      DeathCertificateCorrespondenceTask,
      FoiaRequestCorrespondenceTask,
      OtherMotionCorrespondenceTask,
      PowerOfAttorneyRelatedCorrespondenceTask,
      PrivacyActRequestCorrespondenceTask,
      PrivacyComplaintCorrespondenceTask,
      StatusInquiryCorrespondenceTask
    ]
  end

  def package_action_tasks
    [
      ReassignPackageTask,
      RemovePackageTask,
      SplitPackageTask,
      MergePackageTask
    ]
  end

  def mail_tasks
    [
      AssociatedWithClaimsFolderMailTask,
      AddressChangeCorrespondenceMailTask,
      EvidenceOrArgumentCorrespondenceMailTask,
      VacolsUpdatedMailTask
    ]
  end

  describe ".review_package_task" do
    let!(:correspondence) { create(:correspondence, veteran: veteran) }
    let!(:root_task) { correspondence.root_task }
    let!(:review_package_task) { ReviewPackageTask.find_by(appeal_id: correspondence.id) }

    subject { root_task.review_package_task }

    context "when the correspondence has an open review package task" do
      it "returns the open review package task" do
        expect(subject).to eq(review_package_task)
        expect(subject.open?).to eq(true)

        # check on hold open status
        review_package_task.update!(status: Constants.TASK_STATUSES.on_hold)
        expect(subject).to eq(review_package_task)
        expect(subject.open?).to eq(true)
      end

      it "doesn't return a review package task that is closed" do
        review_package_task.update!(status: Constants.TASK_STATUSES.cancelled)
        expect(subject.nil?).to eq(true)
      end
    end
  end

  describe ".open_intake_task" do
    let!(:correspondence) { create(:correspondence, :with_correspondence_intake_task) }
    let!(:root_task) { correspondence.root_task }
    let!(:intake_task) { CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id) }

    subject { root_task.open_intake_task }

    context "when the correspondence has an open intake task" do
      it "returns the open intake task" do
        expect(subject).to eq(intake_task)
        expect(subject.open?).to eq(true)

        intake_task.update!(status: Constants.TASK_STATUSES.on_hold)
        expect(subject).to eq(intake_task)
        expect(subject.open?).to eq(true)
      end

      it "doesn't return a intake task that is closed" do
        intake_task.update!(status: Constants.TASK_STATUSES.cancelled)
        expect(subject.nil?).to eq(true)
      end
    end
  end

  describe ".open_package_action_task" do
    let!(:correspondence) { create(:correspondence) }
    let!(:root_task) { correspondence.root_task }

    context "when the correspondence has an open package task" do
      it "returns the open package task" do
        package_action_tasks.each do |klass|
          task = klass.create!(
            type: klass.name,
            appeal: correspondence,
            appeal_type: Correspondence.name,
            parent: root_task.review_package_task,
            assigned_to: InboundOpsTeam.singleton
          )
          expect(root_task.open_package_action_task).to eq(task)
          expect(root_task.open_package_action_task.open?).to eq(true)

          # clear out task for next test
          task.destroy
        end
      end

      it "doesn't return a package task that is closed" do
        package_action_tasks.each do |klass|
          task = klass.create!(
            type: klass.name,
            appeal: correspondence,
            appeal_type: Correspondence.name,
            parent: root_task.review_package_task,
            assigned_to: InboundOpsTeam.singleton
          )
          task.update!(status: Constants.TASK_STATUSES.cancelled)
          expect(root_task.open_package_action_task.nil?).to eq(true)

          # clear out task for next test
          task.destroy
        end
      end
    end
  end

  describe ".tasks_not_related_to_an_appeal" do
    let!(:correspondence) { create(:correspondence) }
    let!(:root_task) { correspondence.root_task }

    context "when the correspondence has an open task not related to an appeal" do
      it "returns the open package tasks" do
        tasks_not_related_to_an_appeal.each_with_index do |klass, count|
          task = klass.create!(
            type: klass.name,
            appeal: correspondence,
            appeal_type: Correspondence.name,
            parent: root_task,
            assigned_to: user
          )
          expect(root_task.tasks_not_related_to_an_appeal[count]).to eq(task)
          expect(root_task.tasks_not_related_to_an_appeal[count].open?).to eq(true)
        end
      end
    end
  end

  describe ".correspondence_mail_tasks" do
    let!(:correspondence) { create(:correspondence) }
    let!(:root_task) { correspondence.root_task }

    context "when the correspondence has a mail task" do
      it "returns the mail tasks" do
        mail_tasks.each_with_index do |klass, count|
          task = klass.create!(
            type: klass.name,
            appeal_id: correspondence.id,
            appeal_type: Correspondence.name,
            parent: root_task,
            assigned_to: user
          )
          task.update!(status: Constants.TASK_STATUSES.completed)
          expect(root_task.correspondence_mail_tasks[count]).to eq(task)
        end
      end
    end
  end

  describe ".correspondence_status" do
    let!(:correspondence) { create(:correspondence) }
    let!(:root_task) { correspondence.root_task }

    subject { root_task.correspondence_status }

    context "When the correspondence has an unassigned Review Package Task" do
      it "returns the status unassigned" do
        expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.unassigned)
      end
    end

    context "When the correspondence has an open review package task" do
      it "returns the status as assigned if the task is assigned" do
        correspondence.review_package_task.update!(
          status: Constants.TASK_STATUSES.assigned,
          assigned_to: current_user
        )
        expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.assigned)
      end
      it "returns the status of assigned if the task is on hold" do
        EfolderUploadFailedTask.create!(
          appeal: correspondence,
          appeal_type: Correspondence.name,
          parent: correspondence.review_package_task,
          assigned_to: current_user
        )
        correspondence.review_package_task.update!(status: Constants.TASK_STATUSES.on_hold)
        expect(correspondence.review_package_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.assigned)
      end
    end

    context "When the correspondence has an open intake task" do
      let!(:correspondence) { create(:correspondence, :with_correspondence_intake_task) }

      it "returns the status as assigned if the task is assigned" do
        expect(correspondence.open_intake_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.assigned)
      end
      it "returns the status of assigned if the task is on hold" do
        EfolderUploadFailedTask.create!(
          appeal: correspondence,
          appeal_type: Correspondence.name,
          parent: correspondence.open_intake_task,
          assigned_to: current_user
        )
        correspondence.open_intake_task.update!(status: Constants.TASK_STATUSES.on_hold)
        expect(correspondence.open_intake_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.assigned)
      end
    end

    context "When the correspondence has an open package action task" do
      it "returns the status as action required if the task is assigned" do
        package_action_tasks.each do |klass|
          task = klass.create!(
            type: klass.name,
            appeal: correspondence,
            appeal_type: Correspondence.name,
            parent: root_task.review_package_task,
            assigned_to: InboundOpsTeam.singleton
          )
          expect(root_task.open_package_action_task).to eq(task)
          expect(root_task.open_package_action_task.status).to eq(Constants.TASK_STATUSES.assigned)
          expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.action_required)
          task.destroy
        end
      end
    end

    context "When the correspondence has open tasks not related to an appeal" do
      it "returns the status as pending" do
        correspondence.review_package_task.update!(status: Constants.TASK_STATUSES.completed)
        tasks_not_related_to_an_appeal.each do |klass|
          task = klass.create!(
            type: klass.name,
            appeal: correspondence,
            appeal_type: Correspondence.name,
            parent: root_task.review_package_task,
            assigned_to: user
          )
          expect(root_task.tasks_not_related_to_an_appeal[0]).to eq(task)
          expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.pending)
          task.destroy
        end
      end
    end

    context "When the correspondence has no active children" do
      it "returns the status as completed" do
        correspondence.review_package_task.update!(
          status: Constants.TASK_STATUSES.completed,
          assigned_to: current_user
        )
        root_task.update!(status: Constants.TASK_STATUSES.assigned)
        expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.completed)
      end
    end

    context "When the correspondence has a completed root task" do
      it "returns the status as completed" do
        root_task.update!(status: Constants.TASK_STATUSES.completed)
        root_task.review_package_task.update!(status: Constants.TASK_STATUSES.completed)
        expect(subject).to eq(Constants.CORRESPONDENCE_STATUSES.completed)
      end
    end
  end
end
