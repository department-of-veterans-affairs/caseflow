# frozen_string_literal: true

describe PageRequestedByUserFixJob, :postgres do
  let(:page_error) { "Page requested by the user is unavailable" }
  let(:file_number) { "123456789" }

  let!(:epe) do
    create(:end_product_establishment,
           established_at: Time.zone.now,
           veteran_file_number: file_number)
  end

  let!(:bge) do
    create(:board_grant_effectuation,
           end_product_establishment_id: epe.id,
           decision_sync_error: page_error)
  end
  let!(:bge_2) do
    build(:board_grant_effectuation,
          end_product_establishment_id: nil,
          decision_sync_error: page_error)
  end

  subject { described_class.new }

  it_behaves_like "a Master Scheduler serializable object", PageRequestedByUserFixJob

  context "Board Grant Effectuation error clear" do
    context "when the error exists on BGE"
    describe "when EPE has established_at date" do
      it "clear_error!" do
        subject.perform
        expect(bge.reload.decision_sync_error).to be_nil
      end
    end
    describe "if EPE does not have established_at" do
      it "clears the Page requested by the user is unavailable on the BGE" do
        epe.update(established_at: nil)
        subject.perform
        expect(bge.reload.decision_sync_error).to eq(page_error)
      end
    end
    describe "if EPE does not exist" do
      it "does not clear the error" do
        subject.perform
        expect(bge_2.decision_sync_error).to eq(page_error)
      end
    end
    context "when the BGE does not have the Page requested by the user is unavailable" do
      it "does not attempt to clear the error" do
        bge.update(decision_sync_error: nil)
        subject.perform
        expect(bge.reload.decision_sync_error).to eq(nil)
      end
    end
  end
end
