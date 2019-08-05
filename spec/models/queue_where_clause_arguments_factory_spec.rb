# frozen_string_literal: true

require "rails_helper"

describe QueueWhereClauseArgumentsFactory, :postgres do
  describe ".new" do
    let(:filter_params) { nil }

    subject { QueueWhereClauseArgumentsFactory.new(filter_params: filter_params) }

    context "when input argument is nil" do
      let(:filter_params) { nil }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input argument is a string" do
      let(:filter_params) { "filter_params" }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input argument an empty array" do
      let(:filter_params) { [] }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(QueueWhereClauseArgumentsFactory)
      end
    end

    context "when input argument an array formatted as expected" do
      let(:filter_params) { ["col=#{Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN}&val=#{RootTask.name}"] }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(QueueWhereClauseArgumentsFactory)
      end
    end
  end
end
