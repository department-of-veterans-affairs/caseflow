# frozen_string_literal: true

describe ETL::RemandReasonSyncer, :etl, :all_dbs do
  let!(:remand_reason) { create(:ama_remand_reason) }
  let(:etl_build) { ETL::Build.create }

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "one remand reason" do
      it "syncs attributes" do
        expect(ETL::RemandReason.count).to eq(0)

        subject

        expect(ETL::RemandReason.count).to eq(1)

        expect(ETL::RemandReason.first.code).to eq(remand_reason.code)
        expect(ETL::RemandReason.first.post_aoj).to eq(remand_reason.post_aoj)
        # stringify datetimes to ignore milliseconds
        expect(ETL::RemandReason.first.remand_reason_created_at.to_s).to eq(remand_reason.created_at.to_s)
      end
    end

    context "multiple remand reason records" do
      let!(:remand_reasons) { create_list(:ama_remand_reason, 5) }
      it "syncs attributes" do
        expect(ETL::RemandReason.count).to eq(0)

        subject

        expect(ETL::RemandReason.count).to eq(6)
      end
    end
  end
end
