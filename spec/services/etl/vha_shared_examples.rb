# frozen_string_literal: true

# Shared examples used by vha_*_syncer_spec.rb files for Appeal, HLR, and SC
# Consuming specs must define these methods:
#  originals_count
#

shared_examples "VHA decision review sync" do
  let(:etl_build) { ETL::Build.create }

  describe "#origin_class" do
    subject { described_class.new(etl_build: false).origin_class }

    it { is_expected.to eq origin_class }
  end

  describe "#target_class" do
    subject { described_class.new(etl_build: false).target_class }

    it { is_expected.to eq target_class }
  end

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    before do
      expect(target_class.count).to eq(0)
    end

    context "full sync" do
      it "original/target counts match" do
        expect(originals_count).to eq(1)

        subject

        expect(target_class.count).to eq(1)
      end

      it "populates expected attributes" do
        subject

        target = target_class.first
        expect(target.benefit_type).to eq("vha")
        expect(target.decision_review_id).to_not be_nil
        expect(target.decision_review_type).to_not be_nil
        expect(target.uuid).to_not be_nil
        expect(target.veteran_file_number).to_not be_nil
      end
    end

    # our find_by_primary_key must be polymorphic
    context "incremental with overlapping PKs" do
      let(:appeal) { create(:appeal) }
      let(:hlr) { create(:higher_level_review) }
      let(:sc) { create(:supplemental_claim) }
      let(:syncer) { described_class.new(etl_build: etl_build) }

      before do
        ETL::DecisionReview::Appeal.sync_with_original(appeal).save
        ETL::DecisionReview::HigherLevelReview.sync_with_original(hlr).save
        ETL::DecisionReview::SupplementalClaim.sync_with_original(sc).save
      end

      it "does not cause ActiveRecord::RecordNotUnique error" do
        syncer.call
        expect { syncer.call }.to_not raise_error
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
