# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe OnHoldTasksTab, :postgres do
  let(:tab) { OnHoldTasksTab.new(params) }
  let!(:params) do
    {
      assignee: create(:organization),
      show_regional_office_column: show_regional_office_column
    }
  end
  let(:show_regional_office_column) { false }

  describe ".columns" do
    subject { tab.columns }

    context "when only the assignee argument is passed when instantiating the object" do
      let(:params) { { assignee: create(:organization) } }

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
