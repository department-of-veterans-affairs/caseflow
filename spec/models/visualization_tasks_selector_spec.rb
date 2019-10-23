# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe VisualizationTasksSelector, :postgres do
  describe ".new"  do
    let(:args) { { organization_id: organization_id } }

    subject { VisualizationTasksSelector.new(args) }

    context "when input organization_id argument is nil" do
      let(:organization_id) { nil }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input organization_id is included" do
      let(:organization_id) { create(:organization).id }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(VisualizationTasksSelector)
      end
    end
  end

  describe ".tasks" do
    let(:task_count) { 2 }
    let(:task_type) { GenericTask.name }

    let(:org_assignee) { create(:organization) }
    let(:parent_tasks) do
      create_list(
        :task,
        task_count,
        assigned_to: org_assignee,
        type: task_type,
        assigned_at: 5.days.ago,
        started_at: 4.days.ago,
        placed_on_hold_at: 3.days.ago,
        closed_at: 2.days.ago
      )
    end
    let(:all_parent_tasks) { parent_tasks }

    let(:assignee) { create(:user) }
    let!(:tasks) do
      all_parent_tasks.map do |parent_task|
        create(
          :task,
          assigned_to: assignee,
          type: parent_task.type,
          assigned_at: 5.days.ago,
          started_at: 4.days.ago,
          placed_on_hold_at: 3.days.ago,
          closed_at: 2.days.ago,
          parent: parent_task
        )
      end
    end

    subject { VisualizationTasksSelector.new(args).tasks }

    context "when only the organization is passed" do
      let(:args) { { organization_id: org_assignee.id } }

      context "when there are no child tasks assigned to the organization users" do
        let(:tasks) { nil }

        it "doesn't return any tasks" do
          expect(subject.length).to eq 0
        end
      end

      context "when there are child tasks assigned to the organization users" do
        it "only returns tasks where the parent is assigned to the organization" do
          expect(subject.length).to eq task_count
        end
      end
    end

    context "when filter params are passed" do
      let(:filter_task_type) { IhpColocatedTask.name }
      let(:extra_parent_tasks) do
        create_list(
          :task,
          task_count,
          assigned_to: org_assignee,
          type: filter_task_type,
          assigned_at: 5.days.ago,
          started_at: 4.days.ago,
          placed_on_hold_at: 3.days.ago,
          closed_at: 2.days.ago
        )
      end

      let(:all_parent_tasks) { parent_tasks + extra_parent_tasks }

      let(:args) { { organization_id: org_assignee.id, filter_params: filter_params } }

      context "when filter_params is empty" do
        let(:filter_params) { {} }

        it "returns all tasks" do
          expect(subject.length).to eq all_parent_tasks.length
        end
      end

      context "when filter includes IhpColocatedTasks" do
        let(:filter_params) { { type: filter_task_type } }

        it "returns only ihp tasks assigned to the current organization" do
          expect(subject.length).to eq extra_parent_tasks.length
          expect(subject.map(&:type).uniq).to eq([filter_task_type])
          expect(subject.map(&:id)).to match_array(tasks.select { |task| task.type == filter_task_type }.map(&:id))
        end
      end
    end
  end
end
