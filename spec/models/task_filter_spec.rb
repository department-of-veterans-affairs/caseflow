# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe TaskFilter, :postgres do
  describe ".new"  do
    let(:args) { { filter_params: filter_params } }

    subject { TaskFilter.new(args) }

    context "when input filter_params argument is nil" do
      let(:filter_params) { nil }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input filter_params argument is a string" do
      let(:filter_params) { "filter_params" }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input filter_params argument an empty array" do
      let(:filter_params) { [] }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(TaskFilter)
      end
    end

    context "when input filter_params argument an array formatted as expected" do
      let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN}&val=#{RootTask.name}"] }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(TaskFilter)
      end
    end

    context "when the input tasks argument is not an ActiveRecord::Relation object" do
      let(:args) { { tasks: [create(:generic_task)] } }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when all input arguments are valid" do
      let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN}&val=#{RootTask.name}"] }
      let(:tasks) { Task.where(id: create_list(:generic_task, 6).pluck(:id)) }

      let(:args) { { filter_params: filter_params, tasks: tasks } }

      it "instantiates with given arguments" do
        expect { subject }.to_not raise_error

        expect(subject.filter_params).to eq(filter_params)
        expect(subject.tasks).to eq(tasks)
      end
    end
  end

  describe ".where_clause" do
    subject { TaskFilter.new(filter_params: filter_params).where_clause }

    context "when filter_params is an empty array" do
      let(:filter_params) { [] }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when filtering on task type" do
      let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN}&val=#{RootTask.name}"] }

      it "returns the expected where_clause" do
        expect(subject).to eq([
                                "tasks.type IN (?)",
                                [RootTask.name]
                              ])
      end
    end
  end
end
