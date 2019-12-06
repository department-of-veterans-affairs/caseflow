# frozen_string_literal: true

describe ETL::AppealSyncer, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  describe "#origin_class" do
    subject { described_class.new.origin_class }

    it { is_expected.to eq Appeal }
  end

  describe "#target_class" do
    subject { described_class.new.target_class }

    it { is_expected.to eq ETL::Appeal }
  end

  describe "#call" do
    subject { described_class.new.call }

    context "BVA status distribution" do
      it "has expected distribution" do
        expect(ETL::Appeal.count).to eq(0)

        subject

        expect(ETL::Appeal.count).to eq(13)
      end
    end

    context "sync tomorrow" do
      subject { described_class.new(since: Time.zone.tomorrow).call }

      it "does not sync" do
        expect(ETL::Appeal.count).to eq(0)

        subject

        expect(ETL::Appeal.count).to eq(0)
      end
    end

    context "Appeal is not yet established" do
      let!(:appeal) { create(:appeal, established_at: nil) }

      it "skips non-established Appeals" do
        subject

        expect(ETL::Appeal.count).to eq(13)
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
        subject

        expect(ETL::Appeal.count).to eq(14)
      end
    end
  end
end
