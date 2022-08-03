# frozen_string_literal: true

describe VhaCaregiverSupportUnassignedTasksTab, :postgres do
  let(:tab) { VhaCaregiverSupportUnassignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_reader_link_column: show_reader_link_column
    }
  end
  let(:assignee) {create(:vha_caregiver_support)}
  let(:show_reader_link_column) { false }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaCaregiverSupportUnassignedTasksTab" do
      let(:params) { { assignee: create(:vha_caregiver_support) } }

      it "return the correct number of columns" do
        expect(subject.length).to eq(8)
      end
      it "does not include the reader link column" do
        expect(subject).to_not include(Constants.QUEUE_CONFIG.COLUMNS.DOCKET_COUNT_READER_LINK.name)
      end
    end

    context "when we want to show the reader link column" do
      let(:show_reader_link_column) { true }
      let(:params) { { assignee: create(:vha_caregiver_support),
        show_reader_link_column: show_reader_link_column } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(8)
      end
      it "includes the reader link column" do
        expect(subject).to include(Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name)
      end
    end
  end
end