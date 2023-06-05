# frozen_string_literal: true

describe VhaProgramOffice, :postgres do
  let(:program_office) { VhaProgramOffice.create!(name: "Program Office", url: "Program Office") }

  describe ".create!" do
    it "creates a Vha Program Office" do
      expect(program_office.name).to eq("Program Office")
    end
  end

  describe ".can_receive_task?" do
    let(:appeal) { create(:appeal) }
    let(:doc_task) { create(:vha_document_search_task, appeal: appeal) }

    it "returns false because program offices should not have vha document search tasks assigned to them" do
      expect(program_office.can_receive_task?(doc_task)).to eq(false)
    end
  end

  describe ".queue_tabs" do
    it "returns the expected tabs for use in the VHA Program Office organization's queue" do
      expect(program_office.queue_tabs).to match_array(
        [
          VhaProgramOfficeAssignedTasksTab,
          VhaProgramOfficeInProgressTasksTab,
          VhaProgramOfficeReadyForReviewTasksTab,
          VhaProgramOfficeOnHoldTasksTab,
          VhaProgramOfficeCompletedTasksTab
        ]
      )
    end
  end

  describe ".COLUMN_NAMES" do
    it "VHA Program Office organization queue tabs have 7 columns by default" do
      expect(VhaProgramOffice::COLUMN_NAMES.count).to eq 7
    end
  end
end
