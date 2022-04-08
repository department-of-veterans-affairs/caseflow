# frozen_string_literal: true

describe EduRegionalProcessingOffice, :postgres do
    let(:regional_processing_office) { EduRegionalProcessingOffice.create!(name: "Regional Processing Office", url: "Regional Processing Office") }

    describe ".create!" do
        it "creates a Regional Processing Office" do
          expect(regional_processing_office.name).to eq("Regional Processing Office")
        end
      end
  
  
    describe ".can_receive_task?" do
      let(:appeal) { create(:appeal) }
      let(:doc_task) { create(:education_document_search_task, appeal: appeal) }
  
      it "returns false because program offices should not have edu document search tasks assigned to them" do
        expect(regional_processing_office.can_receive_task?(doc_task)).to eq(false)
      end
    end
  end