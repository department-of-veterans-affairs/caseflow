# frozen_string_literal: true

require "rails_helper"

describe AssignedTasksTab do
  let(:tab) { AssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee_name: assignee_name,
      show_regional_office_column: show_regional_office_column
    }
  end
  let(:assignee_name) { "organization name" }
  let(:show_regional_office_column) { false }

  describe ".columns" do
    subject { tab.columns }

    context "when no arguments are passed when instantiating the object" do
      let(:params) { {} }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end

      it "does not include regional office column" do
        expect(subject).to_not include(Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN)
      end
    end

    context "when we want to show the regional office column" do
      let(:show_regional_office_column) { true }

      it "includes the regional office column" do
        expect(subject).to include(Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN)
      end
    end
  end
end
