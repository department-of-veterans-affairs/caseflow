# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe QueueTab, :postgres do
  # Use AssignedTasksTab as our example since we don't expect QueueTab to ever be instantiated directly.
  let(:tab) { AssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_regional_office_column: show_regional_office_column
    }
  end
  let(:assignee) { create(:organization) }
  let(:show_regional_office_column) { false }

  describe ".allow_bulk_assign?" do
    subject { tab.allow_bulk_assign? }

    context "when only the assignee argument is passed when instantiating the object" do
      let(:params) { { assignee: assignee } }

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

    it "interpolates assignee name in description element of hash" do
      expect(subject[:description]).to eq(format(tab.description, assignee.name))
    end
  end

  describe ".new" do
    subject { tab }

    context "when the assignee is not an organization" do
      let(:assignee) { create(:user) }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when there is no assignee parameter passed when instantiating the tab" do
      let(:params) { { show_regional_office_column: show_regional_office_column } }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when the assignee is an organization" do
      let(:assignee) { create(:organization) }

      it "is created successfully" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(AssignedTasksTab)
      end
    end
  end

  describe "#from_name" do
    subject { QueueTab.from_name(tab_name) }

    context "when not tab class exists with the given name" do
      let(:tab_name) { "non-existent tab name" }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidTaskTableTab)
      end
    end

    context "when a tab class with that name exists" do
      let(:tab_name) { Constants.QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME }

      it "returns the class" do
        expect { subject }.to_not raise_error
        expect(subject).to eq(CompletedTasksTab)
      end
    end
  end
end
