# frozen_string_literal: true

describe CorrespondenceRootTask, :all_dbs do
  let!(:user) { create(:correspondence_auto_assignable_user) }
  let!(:veteran) { create(:veteran) }


  before do
    User.authenticate!(user: user)
    FeatureToggle.enable!(:correspondence_queue)
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
      let!(:package_action_tasks) do
        [
          ReassignPackageTask,
          RemovePackageTask,
          SplitPackageTask,
          MergePackageTask
        ]
      end

      it "returns the open package task" do
        package_action_tasks.each do |klass|
          task = klass.create!(
            type: klass.name,
            appeal: correspondence,
            appeal_type: Correspondence.name,
            parent: root_task.review_package_task,
            assigned_to: user
          )
          root_task.reload
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
            assigned_to: user
          )
          root_task.reload
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
      let!(:tasks_not_related_to_an_appeal) do
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

      it "returns the open package tasks" do
        tasks_not_related_to_an_appeal.each_with_index do |klass, count|
          task = klass.create!(
            type: klass.name,
            appeal: correspondence,
            appeal_type: Correspondence.name,
            parent: root_task,
            assigned_to: user
          )
          root_task.reload
          expect(root_task.tasks_not_related_to_an_appeal[count]).to eq(task)
          expect(root_task.tasks_not_related_to_an_appeal[count].open?).to eq(true)
        end
      end
    end
  end
end
