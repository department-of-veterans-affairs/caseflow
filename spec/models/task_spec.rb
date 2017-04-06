require "rails_helper"
require "ostruct"

class FakeTask < Task
end

describe Task do
  # Clear the task from the DB before every test
  before do
    @one_week_ago = Time.utc(2016, 2, 17, 20, 59, 0) - 7.days
    Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0))

    @user = User.create(station_id: "ABC", css_id: "123", full_name: "Robert Smith")
    @user2 = User.create(station_id: "ABC", css_id: "456", full_name: "Jane Doe")
  end

  context ".newest_first" do
    let!(:appeal1) { Appeal.create(vacols_id: "123C") }
    let!(:task1) { EstablishClaim.create(appeal: appeal1) }
    let!(:appeal2) { Appeal.create(vacols_id: "456D") }
    let!(:task2) { EstablishClaim.create(appeal: appeal2) }
    subject { Task.newest_first }
    before do
      task1.update(created_at: 10.days.ago)
      task2.update(created_at: 1.day.ago)
    end

    it "orders correctly" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.first).to eq(task2)
      expect(subject.last).to eq(task1)
    end
  end

  context ".oldest_first" do
    let!(:appeal1) { Appeal.create(vacols_id: "123C") }
    let!(:task1) { EstablishClaim.create(appeal: appeal1) }
    let!(:appeal2) { Appeal.create(vacols_id: "456D") }
    let!(:task2) { EstablishClaim.create(appeal: appeal2) }
    subject { Task.oldest_first }
    before do
      task1.update(created_at: 10.days.ago)
      task2.update(created_at: 1.day.ago)
    end

    it "orders correctly" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.first).to eq(task1)
      expect(subject.last).to eq(task2)
    end
  end

  context ".unassigned" do
    let!(:appeal1) { Appeal.create(vacols_id: "123C") }
    let!(:task1) { EstablishClaim.create(appeal: appeal1) }
    let!(:appeal2) { Appeal.create(vacols_id: "456D") }
    let!(:task2) { EstablishClaim.create(appeal: appeal2) }
    before do
      task1.update(user: User.create(css_id: "111", station_id: "abc"))
    end
    subject { Task.unassigned }

    it "filters by nil user_id" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.count).to eq(1)
      expect(subject.first).to eq(task2)
    end
  end

  context "Assigning user methods" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    let!(:appeal_same_user) { Appeal.create(vacols_id: "456D") }
    let!(:task_same_user) { EstablishClaim.create(appeal: appeal_same_user) }
    subject { task }

    context ".assign!" do
      before do
        task.prepare!
      end
      it "correctly assigns a task to a user" do
        task.assign!(:assigned, @user)
        expect(subject.user.id).to eq(@user.id)
        expect(subject.assigned_at).not_to be_nil
      end

      it "raises error if already assigned" do
        task.assign!(:assigned, @user)
        expect { task.assign!(:assigned, @user) }.to raise_error(AASM::InvalidTransition)
      end

      it "throws error if user has another task" do
        task_same_user.prepare!
        task.assign!(:assigned, @user)
        expect { task_same_user.assign!(:assigned, @user) }.to raise_error(Task::UserAlreadyHasTaskError)
      end
    end

    context ".assigned?" do
      before do
        task.prepare!
      end
      it "assigned is false before assignment" do
        expect(subject.assigned?).to be_falsey
      end

      it "assigned is true after assignment" do
        task.assign!(:assigned, @user)
        expect(subject.assigned?).to be_truthy
      end
    end
  end

  context ".progress_status" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    subject { task.progress_status }

    # We start with a blank task and move it task through the various states

    context "starts as unassigned" do
      it { is_expected.to eq("Unassigned") }
    end

    context "task is assigned" do
      before do
        task.prepare!
        task.assign!(:assigned, @user)
      end

      it { is_expected.to eq("Not Started") }
    end

    context "task is started" do
      let!(:appeal) { Appeal.create(vacols_id: "123C") }
      let!(:task) { EstablishClaim.create(appeal: appeal) }
      before do
        task.prepare!
        task.assign!(:assigned, @user)
        task.start!
      end
      it { is_expected.to eq("In Progress") }
    end

    context "task is completed" do
      before do
        task.prepare!
        task.assign!(:assigned, @user)
        task.start!
        task.review!
        task.complete!(:completed, status: 0)
      end

      it { is_expected.to eq("Completed") }
    end
  end

  context ".start!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    it "errors if no one is assigned" do
      expect(task.user).to be_nil
      expect { task.start! }.to raise_error(AASM::InvalidTransition)
    end

    it "sets started_at value to current timestamp" do
      task.prepare!
      task.assign!(:assigned, @user)
      expect(task.started_at).to be_falsey
      task.start!
      expect(task.started_at).to eq(Time.now.utc)
    end
  end

  context ".started?" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    subject { task.started? }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
    end

    context "not started" do
      it { is_expected.to be_falsey }
    end

    context "was started" do
      before { task.start! }
      it { is_expected.to be_truthy }
    end
  end

  context ".special_issue_not_emailed?" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    let!(:completion_status) { Task.completion_status_code(:special_issue_not_emailed) }
    subject { task }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
      task.complete!(status: completion_status)
    end
    it { expect(subject.special_issue_not_emailed?).to be_truthy }
  end

  context ".completed?" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    subject { task }
    before { task.completed_at = Time.now.utc }
    it { expect(subject.completed_at).to be_truthy }
  end

  context "#completed_today" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.update_attributes!(completed_at: Time.now.utc)
    end
    it { expect { Task.completed_today.find(task.id) }.not_to raise_error }
  end

  context "#complete_and_recreate!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
      task.review!
      task.complete_and_recreate!(3)
    end
    it "completes and creates a new task" do
      new_task = appeal.tasks.where(type: task.type).where.not(aasm_state: "completed").first
      expect(task.completed?).to be_truthy
      expect(task.id).not_to eq(new_task.id)
    end

    it "fails on already completed tasks" do
      expect(task.reload.completed?).to be_truthy
      expect { task.cancel! }.to raise_error(AASM::InvalidTransition)
    end
  end

  context "#complete!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
      task.review!
    end

    it "completes the task" do
      task.complete!(:completed, status: 3)
      expect(task.reload.completed_at).to be_truthy
      expect(task.completion_status).to eq(3)
    end

    it "errors if already complete" do
      task.complete!(:completed, status: 3)

      expect { task.complete!(:completed, status: 2) }.to raise_error(AASM::InvalidTransition)

      # Confirm complete values are still the original
      expect(task.reload.completed_at).not_to be_nil
      expect(task.completion_status).to eq(3)
    end
  end

  context "#to_complete" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
    end
    it { expect { Task.to_complete.find(task.id) }.not_to raise_error }
  end

  context "#expire!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
    end
    it "closes unfinished tasks" do
      task.expire!
      expect(task.reload.completed?).to be_truthy
      expect(task.reload.completion_status).to eq(Task.completion_status_code(:expired))
      expect(appeal.tasks.where.not(aasm_state: "completed").where(type: :EstablishClaim).count).to eq(1)
    end

    it "closes unfinished task in review state" do
      task.review!
      task.expire!
      expect(task.reload.completed?).to be_truthy
      expect(task.reload.completion_status).to eq(Task.completion_status_code(:expired))
      expect(appeal.tasks.where.not(aasm_state: "completed").where(type: :EstablishClaim).count).to eq(1)
    end
  end

  context "#cancel!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
    end
    it "closes canceled tasks" do
      task.cancel!
      expect(task.reload.completed?).to be_truthy
      expect(task.reload.completion_status).to eq(Task.completion_status_code(:canceled))
      expect(appeal.tasks.to_complete.where(type: :EstablishClaim).count).to eq(0)
    end

    it "saves feedback" do
      task.cancel!("Feedback")
      expect(task.reload.comment).to eq("Feedback")
    end
  end

  context "#prepare_with_decision!" do
    subject { task.prepare_with_decision! }

    let(:appeal) do
      Generators::Appeal.create(
        vacols_record: {template: :partial_grant_decided, decision_date: 7.days.ago},
        documents: documents
      )
    end
    let(:task) { EstablishClaim.create(appeal: appeal) }

    context "if the task's appeal has no decisions" do
      let(:documents) { [] }
      it { is_expected.to be_falsey }
    end

    context "if the task's appeal has decisions" do
      let(:documents) { [Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)] }
      let(:filename) { appeal.decisions.first.file_name }

      context "if the task's appeal errors out on decision content load" do
        before do
          expect(Appeal.repository).to receive(:fetch_document_file).and_raise("VBMS 500")
        end

        it "propogates exception and does not prepare" do
          expect { subject }.to raise_error("VBMS 500")
          expect(task.reload).to_not be_unassigned
        end
      end

      context "if the task caches decision content successfully" do
        before do
          expect(Appeal.repository).to receive(:fetch_document_file) { "yay content!" }
        end

        it "prepares task and caches decision document content" do
          expect(subject).to be_truthy

          expect(task.reload).to be_unassigned
          expect(S3Service.files[filename]).to eq("yay content!")
        end
      end
    end
  end

  context ".canceled?" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
    end
    it "returns false for task not canceled" do
      expect(task.canceled?).to be_falsey
    end

    it "returns true for canceled task" do
      task.cancel!
      expect(task.canceled?).to be_truthy
    end

    it "can be canceled when in review state" do
      task.review!
      task.cancel!
      expect(task.canceled?).to be_truthy
    end
  end

  context "#assigned_not_completed" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
    end
    it { expect { Task.assigned_not_completed.find(task.id) }.not_to raise_error }
  end

  context "#days_since_creation" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal, created_at: @one_week_ago) }
    it "returns the correct number of days" do
      expect(task.days_since_creation).to eq(7)
    end
  end

  context "#unprepared" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    it "returns unprepared tasks" do
      expect(Task.unprepared.first).to eq(task)
    end
  end

  context "#no_review_completion_status" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    let!(:no_review_status) { Task.completion_status_code(:special_issue_not_emailed) }
    let!(:review_status) { Task.completion_status_code(:completed) }
    it "returns true if no_review_status" do
      expect(task.no_review_completion_status(status: no_review_status)).to eq(true)
    end
    it "returns false if status has to be reviewed" do
      expect(task.no_review_completion_status(status: review_status)).to eq(false)
    end
  end

  context "#tasks_completed_by_users" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:tasks) do
      [
        EstablishClaim.create(appeal: appeal),
        EstablishClaim.create(appeal: appeal),
        EstablishClaim.create(appeal: appeal)
      ]
    end

    before do
      tasks.each_with_index do |task, index|
        task.prepare!
        if index < 2
          task.assign!(:assigned, @user)
        else
          task.assign!(:assigned, @user2)
        end
        task.start!
        task.review!
        task.complete!(status: 0)
      end
    end

    it "returns hash with each user and their completed number of tasks" do
      expect(Task.tasks_completed_by_users(tasks)).to eq("Jane Doe" => 1, "Robert Smith" => 2)
    end
  end
end
