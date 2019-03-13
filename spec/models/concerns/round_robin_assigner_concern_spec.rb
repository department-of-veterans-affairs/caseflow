# frozen_string_literal: true

describe RoundRobinAssigner do
  class RoundRobinAssignedTask < Task
    include RoundRobinAssigner

    class << self
      attr_accessor :list_of_assignees
    end
  end

  describe ".latest_task" do
    context "when no tasks of type have been created" do
      before { RoundRobinAssignedTask.destroy_all }
      it "should return nil" do
        expect(RoundRobinAssignedTask.latest_task).to eq(nil)
      end
    end

    context "when task assigned to User exists" do
      let!(:task) do
        RoundRobinAssignedTask.create(
          assigned_by: FactoryBot.create(:user),
          assigned_to: FactoryBot.create(:user),
          appeal: FactoryBot.create(:appeal),
          appeal_type: Appeal.name
        )
      end
      it "should return the most recent task" do
        expect(RoundRobinAssignedTask.latest_task.id).to eq(task.id)
      end
    end

    context "when task assigned to Organization is most recent task" do
      let!(:user_task) do
        RoundRobinAssignedTask.create(
          assigned_by: FactoryBot.create(:user),
          assigned_to: FactoryBot.create(:user),
          appeal: FactoryBot.create(:appeal),
          appeal_type: Appeal.name
        )
      end
      let!(:org_task) do
        RoundRobinAssignedTask.create(
          assigned_by: user_task.assigned_to,
          assigned_to: FactoryBot.create(:organization),
          appeal: user_task.appeal,
          appeal_type: user_task.appeal_type,
          parent: user_task
        )
      end

      it "should return the most recent task assigned to a User" do
        expect(RoundRobinAssignedTask.latest_task.id).to eq(user_task.id)
      end
    end
  end

  describe ".next_assignee" do
    context "when the list_of_assignees is an empty array" do
      before { RoundRobinAssignedTask.list_of_assignees = [] }
      it "should raise an error" do
        expect { RoundRobinAssignedTask.next_assignee }.to(raise_error) do |e|
          expect(e.message).to eq("list_of_assignees cannot be empty")
        end
      end
    end

    context "when the list_of_assignees is a populated array" do
      let(:assignees) { %w[Harry Hermione Ron] }
      let(:iterations) { 4 }
      let(:total_distribution_count) { iterations * assignees.length }

      before do
        assignees.each { |a| FactoryBot.create(:user, css_id: a) }
        RoundRobinAssignedTask.list_of_assignees = assignees
      end

      it "should evenly distribute tasks to assignees" do
        total_distribution_count.times do
          RoundRobinAssignedTask.create(
            assigned_by: FactoryBot.create(:user),
            assigned_to: RoundRobinAssignedTask.next_assignee,
            appeal: FactoryBot.create(:appeal),
            appeal_type: Appeal.name
          )
        end

        assignees.each do |a|
          expect(RoundRobinAssignedTask.select { |t| t.assigned_to.css_id == a }.count).to eq(iterations)
        end
      end
    end
  end
end
