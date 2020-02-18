# frozen_string_literal: true

describe ETL::AppealSyncer, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  let(:etl_build) { ETL::Build.create }

  describe "#origin_class" do
    subject { described_class.new.origin_class }

    it { is_expected.to eq Appeal }
  end

  describe "#target_class" do
    subject { described_class.new.target_class }

    it { is_expected.to eq ETL::Appeal }
  end

  describe "#call" do
    subject { described_class.new.call(etl_build) }

    before do
      expect(ETL::Appeal.count).to eq(0)
    end

    context "BVA status distribution" do
      it "has expected distribution" do
        subject

        expect(ETL::Appeal.count).to eq(13)
      end

      it "populates person attributes" do
        subject

        appeal = ETL::Appeal.first
        expect(appeal.veteran_dob).to_not be_nil
        expect(appeal.claimant_dob).to_not be_nil
        expect(appeal.aod_due_to_dob).to_not be_nil
      end
    end

    context "sync tomorrow" do
      subject { described_class.new(since: Time.zone.now + 1.day).call(etl_build) }

      it "does not sync" do
        subject

        expect(ETL::Appeal.count).to eq(0)
      end
    end

    context "Appeal is not yet established" do
      let!(:appeal) { create(:appeal, established_at: nil) }

      it "skips non-established Appeals" do
        etl_build_table = subject

        expect(ETL::Appeal.count).to eq(13)
        expect(etl_build_table.rows_rejected).to eq(0) # not part of .filter so we can't know about it.
        expect(etl_build_table.rows_inserted).to eq(13)
      end
    end

    context "Appeal has no claimant" do
      let!(:appeal) do
        # no factory because we do not want claimant
        Appeal.create!(
          receipt_date: Time.zone.yesterday,
          established_at: Time.zone.now,
          docket_type: Constants.AMA_DOCKETS.evidence_submission,
          veteran_file_number: create(:veteran).file_number
        )
      end

      it "syncs" do
        expect { subject }.to_not raise_error

        expect(ETL::Appeal.count).to eq(14)
      end
    end
  end
end
