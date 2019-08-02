# frozen_string_literal: true

require "rails_helper"

describe TrackingTasksTab do
  let(:tab) { TrackingTasksTab.new(params) }
  let(:params) { { assignee_name: assignee_name } }
  let(:assignee_name) { "organization name" }

  describe ".columns" do
    subject { tab.columns }

    context "when no arguments are passed when instantiating the object" do
      let(:params) { {} }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(4)
      end
    end

    context "when arguments are passed when instantiating the object" do
      it "returns the correct number of columns" do
        expect(subject.length).to eq(4)
      end
    end
  end
end
