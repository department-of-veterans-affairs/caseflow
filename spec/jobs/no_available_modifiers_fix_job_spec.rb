# frozen_string_literal: true

describe NoAvailableModifiersFixJob, :postgres do
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
                                               source_type: "HigherLevelReview", synced_status: "CLR")

    create_list(:end_product_establishment, 5, veteran_file_number: file_number, modifier: "040",
                                               source_type: "SupplementalClaim", synced_status: "CAN")
  end

  subject { described_class.new }

  it_behaves_like "a Master Scheduler serializable object", NoAvailableModifiersFixJob

  context "when there are fewer than 10 active end products" do
    describe "when there are 0 active end products" do
      it "runs decision_review_process_job on up to 10 Supplemental Claims" do
        subject.perform

        expect(supplemental_claim_with_error.reload.establishment_error).to be_nil
        expect(supplemental_claim_with_error_2.reload.establishment_error).to be_nil
      end
    end

    describe "when there are 9 active end products" do
      before do
        create_list(:end_product_establishment, 4, veteran_file_number: file_number, modifier: "040",
                                                   source_type: "SupplementalClaim", synced_status: "PEND")
        create_list(:end_product_establishment, 5, veteran_file_number: file_number, modifier: "040",
                                                   source_type: "SupplementalClaim", synced_status: "RW")
      end

      it "runs decision_review_process_job on 1 Supplemental Claim" do
        all_with_errors = SupplementalClaim.where(establishment_error: error_text)
        subject.perform
        expect(all_with_errors.where(establishment_error: error_text).count).to eq(1)
      end
    end

    describe "when there are 5 active end products" do
      before do
        create_list(:end_product_establishment, 5, veteran_file_number: file_number, modifier: "040",
                                                   source_type: "SupplementalClaim", synced_status: "PEND")
        create_list(:supplemental_claim, 6, veteran_file_number: file_number,
                                            establishment_error: error_text)
        # Total number of SC with errors is now 8
      end

      it "runs decision_review_process_job on up to 5 Supplemental Claims" do
        all_with_errors = SupplementalClaim.where(establishment_error: error_text)

        to_be_cleared = all_with_errors.sample([5, all_with_errors.count].min)

        expect do
          subject.perform
          to_be_cleared.each(&:reload) # Reload each selected record after subject.perform
        end.to(change { to_be_cleared.map(&:establishment_error) })

        expect(all_with_errors.where(establishment_error: error_text).count).to eq(3)
      end
    end
  end

  context "when there are 10 active end products" do
    before do
      create_list(:end_product_establishment, 10, veteran_file_number: file_number, modifier: "040",
                                                  source_type: "SupplementalClaim", synced_status: "PEND")
    end

    it "does not run decision_review_process_job on any Supplemental Claims" do
      all_with_errors = SupplementalClaim.where(establishment_error: error_text)
      subject.perform
      expect(all_with_errors.where(establishment_error: error_text).count).to eq(2)
    end

    describe "when there are more than 10 active end products" do
      it "does not run decision_review_process_job on any Supplemental Claims" do
        epe.update(synced_status: "PEND")
        all_with_errors = SupplementalClaim.where(establishment_error: error_text)
        subject.perform
        expect(all_with_errors.where(establishment_error: error_text).count).to eq(2)
      end
    end
  end
end
