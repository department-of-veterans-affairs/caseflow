# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe TrackingTasksTab, :postgres do
  let(:tab) { TrackingTasksTab.new(params) }
  let!(:params) { { assignee: create(:organization) } }

  describe ".columns" do
    subject { tab.columns }

    it "returns the correct number of columns" do
      expect(subject.length).to eq(4)
    end
  end
end
