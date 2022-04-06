# frozen_string_literal: true

describe EduRegionalProcessingOffice, :postgres do
    let(:regional_processing_office) { VhaRegionalOffice.create!(name: "Regional Office", url: "regional-office") }
  
  
    describe ".can_receive_task?" do
      let(:appeal) { create(:appeal) }
      let(:doc_task) { create(:vha_document_search_task, appeal: appeal) }
  
      it "returns false because program offices should not have vha document search tasks assigned to them" do
        expect(regional_processing_office.can_receive_task?(doc_task)).to eq(false)
      end
    end
  end