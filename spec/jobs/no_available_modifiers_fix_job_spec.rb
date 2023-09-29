# frozen_string_literal: true

describe NoAvailableModifiersFixJob, :postres do
  let(:error_text) { "EndProductModifierFinder::NoAvailableModifiers" }
  let(:file_number) { "123454321" }

  let!(:vet) do
    create(
      :veteran,
      file_number: file_number
    )
  end

  let!(:supplemental_claim_with_error) do
    create(
      :supplemental_claim,
      veteran_file_number: file_number,
      establishment_error: error_text
    )
  end
  let!(:supplemental_claim_with_error_2) do
    create(
      :supplemental_claim,
      veteran_file_number: file_number,
      establishment_error: error_text
    )
  end

  let!(:epe) do
    create(
      :end_product_establishment,
      veteran_file_number: file_number,
      source_type: "SupplementalClaim",
      source_id: supplemental_claim_with_error.id,
      modifier: nil
    )
  end

  before do
    create_list(:end_product_establishment, 5, veteran_file_number: file_number, modifier: nil,
                                               source_type: "SupplementalClaim")
    create_list(:end_product_establishment, 2, veteran_file_number: file_number, modifier: "030",
                                               source_type: "HigherLevelReview")
  end

  subject { described_class.new }

  context "when there are fewer than 10 active end products" do
    describe "when there are 0 active end products" do
      it "runs decision_review_process_job on up to 10 Supplemental Claims" do
        expect(subject.decision_review_job).to receive(:perform).twice.with(anything)
        subject.perform
      end
    end

    describe "when there are 0 active end products" do
      it "runs decision_review_process_job on up to 5 Supplemental Claims" do
        subject.perform
      end
    end
  end
end
