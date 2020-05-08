# frozen_string_literal: true

# Shared examples used by vha_*_syncer_spec.rb files for Appeal, HLR, and SC

shared_examples "VHA decision review sync" do
  let(:etl_build) { ETL::Build.create }

  describe "#origin_class" do
    subject { described_class.new(etl_build: etl_build).origin_class }

    it { is_expected.to eq origin_class }
  end

  describe "#target_class" do
    subject { described_class.new(etl_build: etl_build).target_class }

    it { is_expected.to eq target_class }
  end

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    before do
      expect(target_class.count).to eq(0)
    end

    context "BVA status distribution" do
      it "has expected distribution" do
        expect(vha_decision_reviews_count).to eq(1)
        subject

        expect(target_class.count).to eq(1)
      end

      it "populates expected attributes" do
        subject

        dr = target_class.first
        expect(dr.benefit_type).to eq("vha")
        expect(dr.decision_review_id).to_not be_nil
        expect(dr.decision_review_type).to_not be_nil
        expect(dr.uuid).to_not be_nil
        expect(dr.veteran_file_number).to_not be_nil
      end
    end

    context "sync tomorrow" do
      subject { described_class.new(since: Time.zone.now + 1.day, etl_build: etl_build).call }

      it "does not sync" do
        subject

        expect(target_class.count).to eq(0)
      end
    end
  end
end
