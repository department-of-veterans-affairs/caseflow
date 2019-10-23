# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

fdescribe VisualizationTasksSelector, :postgres do
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

    let(:organization_id) { create(:organization).id }

    let(:assignee) { create(:user) }
    let!(:tasks) do
      create_list(
        :task,
        task_count,
        assigned_to: assignee,
        type: task_type,
        assigned_at: 5.days.ago,
        started_at: 4.days.ago,
        placed_on_hold_at: 3.days.ago,
        closed_at: 2.days.ago
      )
    end

    subject { VisualizationTasksSelector.new(args).tasks }

    context "when only the organization is passed" do
      let(:args) { { organization_id: organization_id } }

      it "returns all tasks" do
        expect(subject.length).to eq task_count
      end
    end

    # context "when filtering by task type" do
    #   let(:foia_tasks) { create_list(:foia_task, 5) }
    #   let(:translation_tasks) { create_list(:translation_task, 6) }
    #   let(:generic_tasks) { create_list(:generic_task, 7) }
    #   let(:all_tasks) do
    #     Task.where(id: foia_tasks.pluck(:id) + translation_tasks.pluck(:id) + generic_tasks.pluck(:id))
    #   end

    #   context "when filter_params is an empty array" do
    #     let(:filter_params) { [] }

    #     it "returns the same set of tasks for the filtered and unfiltered set" do
    #       expect(subject.map(&:id)).to match_array(all_tasks.map(&:id))
    #     end
    #   end

    #   context "when filter includes TranslationTasks" do
    #     let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{TranslationTask.name}"] }

    #     it "returns only translation tasks assigned to the current organization" do
    #       expect(subject.map(&:id)).to_not match_array(all_tasks.map(&:id))
    #       expect(subject.map(&:type).uniq).to eq([TranslationTask.name])
    #       expect(subject.map(&:id)).to match_array(translation_tasks.map(&:id))
    #     end
    #   end

    #   context "when filter includes TranslationTasks and FoiaTasks" do
    #     let(:filter_params) do
    #       ["col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{TranslationTask.name},#{FoiaTask.name}"]
    #     end

    #     it "returns all translation and FOIA tasks assigned to the current organization" do
    #       expect(subject.map(&:type).uniq).to match_array([TranslationTask.name, FoiaTask.name])
    #       expect(subject.map(&:id)).to match_array(translation_tasks.map(&:id) + foia_tasks.map(&:id))
    #     end
    #   end
    # end
  end
end
