# frozen_string_literal: true

require "rails_helper"

describe QueueTab do
  # Use AssignedTasksTab as our example since we don't expect QueueTab to ever be instantiated directly.
  let(:tab) { AssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee_name: assignee_name,
      show_regional_office_column: show_regional_office_column
    }
  end
  let(:assignee_name) { "organization name" }
  let(:show_regional_office_column) { false }

  describe ".allow_bulk_assign?" do
    subject { tab.allow_bulk_assign? }

    context "when no arguments are passed when instantiating the object" do
      let(:params) { {} }

      it "returns false" do
        expect(subject).to eq(false)
      end
    end
  end

  describe ".to_hash" do
    subject { tab.to_hash }

    it "returns a hash with the correct keys" do
      expect(subject.keys).to match_array([:label, :name, :description, :columns, :allow_bulk_assign])
    end

    it "interpolates assignee_name name in description element of hash" do
      expect(subject[:description]).to eq(format(tab.description, assignee_name))
    end
  end
end
