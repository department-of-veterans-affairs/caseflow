# frozen_string_literal: true

describe BgsShareErrorFixJob, :postgres do
  let(:share_error) { "BGS::ShareError" }
  let(:file_number) { "123456789" }
  let!(:hlr) do
    create(:higher_level_review,
           establishment_error: share_error,
           veteran_file_number: file_number)
  end
  let!(:epe) do
    create(:end_product_establishment,
           source: hlr,
           established_at: Time.zone.now,
           veteran_file_number: file_number)
  end

  subject { described_class.new }

  context "BGS::ShareError" do
    context "HLR" do
      context "when the error exists on HigherLevelReview"
      describe "when EPE has established_at date" do
        it "clears the BGS::ShareError on the HLR" do
          subject.perform
          expect(hlr.reload.establishment_error).to be_nil
        end
      end
      describe "when EPE does not have established_at date" do
        it "does not clear the BGS::ShareError on the HLR" do
          epe.update(established_at: nil)
          subject.perform
          expect(hlr.reload.establishment_error).to eq(share_error)
        end
      end
      context "when the hlr does not have the BGS::ShareError" do
        it "does not attempt to clear the error" do
          hlr.update(establishment_error: nil)
          subject.perform
          expect(hlr.reload.establishment_error).to eq(nil)
        end
      end
    end

    context "RIU" do
      let!(:hlr_2) { create(:higher_level_review) }

      let!(:riu) do
        create(:request_issues_update,
               error: share_error,
               review_id: 65,
               review_type: hlr_2)
      end
      let!(:epe_2) do
        create(:end_product_establishment,
               id: riu.review_id,
               established_at: Time.zone.now,
               veteran_file_number: 3_231_213_123)
      end

      context "when the error exists on  RIU"
      describe "when EPE has established_at date" do
        it "clears the BGS::ShareError on the RIU" do
          subject.perform
          expect(riu.reload.error).to be_nil
        end
      end
      describe "when EPE does not have established_at date" do
        it "does not clear the BGS::ShareError on the HLR" do
          epe_2.update(established_at: nil)
          subject.perform
          expect(riu.reload.error).to eq(share_error)
        end
      end
      context "when the RIU does not have the BGS::ShareError" do
        it "does not attempt to clear the error" do
          riu.update(error: nil)
          subject.perform
          expect(riu.reload.error).to eq(nil)
        end
      end
    end

    context "BGE" do
      let!(:epe_3) do
        create(:end_product_establishment,
               established_at: Time.zone.now, veteran_file_number: 88_888_888)
      end
      let!(:bge) do
        create(:board_grant_effectuation,
               end_product_establishment_id: epe_3.id,
               decision_sync_error: share_error)
      end

      context "when the error exists on RIU"
      describe "when EPE has established_at date" do
        it "clear_error!" do
          subject.perform
          expect(bge.reload.decision_sync_error).to be_nil
        end
      end
      describe "if EPE does not have established_at" do
        it "clears the BGS::ShareError on the HLR" do
          epe_3.update(established_at: nil)
          subject.perform
          expect(bge.reload.decision_sync_error).to eq(share_error)
        end
      end
      context "when the BGE does not have the BGS::ShareError" do
        it "does not attempt to clear the error" do
          bge.update(decision_sync_error: nil)
          subject.perform
          expect(bge.reload.decision_sync_error).to eq(nil)
        end
      end
    end
  end
end
