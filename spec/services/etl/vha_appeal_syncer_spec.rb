# frozen_string_literal: true

require_relative "./vha_shared_examples"

describe ETL::VhaAppealSyncer, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  let(:origin_class) { Appeal }
  let(:target_class) { ETL::VhaAppeal }
  before { create(:request_issue, benefit_type: "vha") }

  def vha_appeal_ids
    RequestIssue.select(:decision_review_id).where(benefit_type: "vha", decision_review_type: :Appeal)
  end

  def vha_decision_reviews_count
    Appeal.where(id: vha_appeal_ids).count
  end

  include_examples "VHA decision review sync"

  describe "Appeal#call" do
    let(:etl_build) { ETL::Build.create }
    subject { described_class.new(etl_build: etl_build).call }

    context "Appeal is not yet established" do
      let!(:appeal) { create(:appeal, established_at: nil) }
      let(:etl_build_table) { ETL::BuildTable.find_by(table_name: "vha_decision_reviews") }

      it "skips non-established Appeals" do
        subject

        expect(target_class.count).to eq(1)
        expect(etl_build_table.rows_rejected).to eq(0) # not part of .filter so we can't know about it.
        expect(etl_build_table.rows_inserted).to eq(1)
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

        expect(ETL::VhaAppeal.count).to eq(1)
      end
    end
  end
end
