# frozen_string_literal: true

describe OrgCorrespondenceConfig, :postgres do
  describe ".to_hash" do
    let(:org) { create(:organization) }

    subject { described_class.new(assignee: org).to_hash }

    describe "shape of the returned hash" do
      it "returns the correct top level keys in the response" do
        expect(subject.keys).to match_array([:table_title, :active_tab, :tasks_per_page, :use_task_pages_api, :tabs])
      end
    end

    describe "title" do
      it "is formatted as expected" do
        expect(subject[:table_title]).to eq("Correspondence cases")
      end
    end

    describe "active_tab" do
      it "is the unassigned tab" do
        expect(subject[:active_tab]).to eq("correspondence_unassigned")
      end
    end

    describe "tabs array" do
      it "has the correct tabs" do
        expect(subject[:tabs].map do |tab|
          tab[:label]
        end).to eq(%w[Unassigned Action\ Required Pending Assigned Completed])
      end

      it "tabs have the correct columns" do
        expect(subject[:tabs].find { |tab| tab[:label] == "Unassigned" }[:columns]
        .map { |column| column[:name] })
          .to eq(%w[checkboxColumn veteranDetails vaDor daysWaitingCorrespondence notes])

        expect(subject[:tabs].find { |tab| tab[:label] == "Action Required" }[:columns]
        .map { |column| column[:name] })
          .to eq(%w[veteranDetails vaDor daysWaitingCorrespondence assignedByColumn actionType notes])

        expect(subject[:tabs].find { |tab| tab[:label] == "Pending" }[:columns]
        .map { |column| column[:name] })
          .to eq(%w[veteranDetails vaDor daysWaitingCorrespondence taskColumn assignedToColumn])

        expect(subject[:tabs].find { |tab| tab[:label] == "Assigned" }[:columns]
        .map { |column| column[:name] })
          .to eq(%w[checkboxColumn veteranDetails vaDor daysWaitingCorrespondence taskColumn assignedToColumn notes])

        expect(subject[:tabs].find { |tab| tab[:label] == "Completed" }[:columns]
        .map { |column| column[:name] })
          .to eq(%w[veteranDetails vaDor completedDateColumn notes])
      end
    end
  end
end
