# frozen_string_literal: true

describe CorrespondenceAutoAssignLogger do
  subject(:described) { described_class.new(current_user, batch_auto_assignment_attempt) }

  let(:current_user) { create(:user) }
  let(:assignee) { create(:user) }
  let(:batch_auto_assignment_attempt) { create(:batch_auto_assignment_attempt, user: current_user) }

  let!(:correspondence) { create(:correspondence) }
  let(:task) { correspondence.review_package_task }

  describe ".fail_run_validation" do
    it "updates the BatchAutoAssignmentAttempt record to a failed state" do
      described_class.fail_run_validation(
        batch_auto_assignment_attempt_id: batch_auto_assignment_attempt.id,
        msg: "Test error"
      )

      batch = BatchAutoAssignmentAttempt.first
      expect(batch.status).to eq("error")
      expect(batch.error_info["message"]).to eq("Test error")
    end
  end

  describe "#begin" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end
    it "creates a BatchAutoAssignmentAttempt record" do
      expect do
        described.begin
      end.to change(BatchAutoAssignmentAttempt, :count).by(1)

      batch = BatchAutoAssignmentAttempt.first
      expect(batch.user).to eq(current_user)
      expect(batch.status).to eq("started")
    end
  end

  describe "#end" do
    it "completes the BatchAutoAssignmentAttempt record" do
      expect do
        described.begin
        described.end
      end.to change(BatchAutoAssignmentAttempt, :count).by(1)

      batch = BatchAutoAssignmentAttempt.last
      expect(batch.status).to eq("completed")
      expect(batch.statistics["seconds_elapsed"]).to be > 0
    end
  end

  describe "#error" do
    it "completes the BatchAutoAssignmentAttempt record with an error state" do
      expect do
        described.begin
        described.error(msg: "Test error")
      end.to change(BatchAutoAssignmentAttempt, :count).by(1)

      batch = BatchAutoAssignmentAttempt.last
      expect(batch.status).to eq("error")
      expect(batch.error_info["message"]).to eq("Test error")
    end
  end

  describe "#assigned" do
    let(:assignee) { create(:user) }

    before do
      described.begin
    end

    it "creates an IndividualAutoAssignmentAttempt record with the results of the assignment" do
      expect do
        described.assigned(task: task, started_at: Time.current, assigned_to: assignee)
      end.to change(IndividualAutoAssignmentAttempt, :count).by(1)

      result = IndividualAutoAssignmentAttempt.last
      expect(result.status).to eq("completed")
      expect(result.statistics["review_package_task_id"]).to eq(task.id)
    end
  end

  describe "#no_eligible_assignees" do
    before do
      described.begin
    end

    it "creates an IndividualAutoAssignmentAttempt record indicating no assignees" do
      expect do
        described.no_eligible_assignees(
          task: task,
          started_at: Time.current,
          unassignable_reason: "No eligible assignees available"
        )
      end.to change(IndividualAutoAssignmentAttempt, :count).by(1)

      result = IndividualAutoAssignmentAttempt.last
      expect(result.status).to eq("error")
      expect(result.statistics["review_package_task_id"]).to eq(task.id)
      expect(result.statistics["result"]).to eq(
        "No eligible assignees: No eligible assignees available"
      )
    end
  end

  describe "tracking assignments" do
    let!(:nod_correspondence) { create(:correspondence, :nod) }
    let(:nod_task) { nod_correspondence.review_package_task }

    before do
      described.begin
    end

    context "when there are eligible assignees" do
      it "increments num_packages_assigned" do
        described.assigned(task: task, started_at: Time.current, assigned_to: assignee)
        described.end

        batch = BatchAutoAssignmentAttempt.last
        expect(batch.num_packages_assigned).to eq(1)
        expect(batch.num_packages_unassigned).to eq(0)
        expect(batch.num_nod_packages_assigned).to eq(0)
        expect(batch.num_nod_packages_unassigned).to eq(0)
      end

      context "with NOD correspondence" do
        it "increments num_nod_packages_assigned" do
          described.assigned(task: nod_task, started_at: Time.current, assigned_to: assignee)
          described.end

          batch = BatchAutoAssignmentAttempt.last
          expect(batch.num_packages_assigned).to eq(0)
          expect(batch.num_packages_unassigned).to eq(0)
          expect(batch.num_nod_packages_assigned).to eq(1)
          expect(batch.num_nod_packages_unassigned).to eq(0)
        end
      end
    end

    context "when there are NO eligible assignees" do
      it "increments num_packages_unassigned" do
        described.no_eligible_assignees(
          task: task,
          started_at: Time.current,
          unassignable_reason: "No eligible assignees available"
        )
        described.end

        batch = BatchAutoAssignmentAttempt.last
        expect(batch.num_packages_assigned).to eq(0)
        expect(batch.num_packages_unassigned).to eq(1)
        expect(batch.num_nod_packages_assigned).to eq(0)
        expect(batch.num_nod_packages_unassigned).to eq(0)
      end

      context "with NOD correspondence" do
        it "increments num_nod_packages_unassigned" do
          described.no_eligible_assignees(
            task: nod_task, started_at: Time.current,
            unassignable_reason: "No eligible assignees available"
          )
          described.end

          batch = BatchAutoAssignmentAttempt.last
          expect(batch.num_packages_assigned).to eq(0)
          expect(batch.num_packages_unassigned).to eq(0)
          expect(batch.num_nod_packages_assigned).to eq(0)
          expect(batch.num_nod_packages_unassigned).to eq(1)
        end
      end
    end

    context "multiple assignments" do
      it "correctly increments the number of assigned packages" do
        num_packages_assigned = rand(1..10)
        num_packages_unassigned = rand(1..10)
        num_nod_packages_assigned = rand(1..10)
        num_nod_packages_unassigned = rand(1..10)

        num_packages_assigned.times do
          described.assigned(task: task, started_at: Time.current, assigned_to: assignee)
        end

        num_packages_unassigned.times do
          described.no_eligible_assignees(
            task: task, started_at: Time.current,
            unassignable_reason: "No eligible assignees available"
          )
        end

        num_nod_packages_assigned.times do
          described.assigned(task: nod_task, started_at: Time.current, assigned_to: assignee)
        end

        num_nod_packages_unassigned.times do
          described.no_eligible_assignees(
            task: nod_task, started_at: Time.current,
            unassignable_reason: "No eligible assignees available"
          )
        end

        described.end

        batch = BatchAutoAssignmentAttempt.last
        expect(batch.num_packages_assigned).to eq(num_packages_assigned)
        expect(batch.num_packages_unassigned).to eq(num_packages_unassigned)
        expect(batch.num_nod_packages_assigned).to eq(num_nod_packages_assigned)
        expect(batch.num_nod_packages_unassigned).to eq(num_nod_packages_unassigned)
      end
    end
  end
end
