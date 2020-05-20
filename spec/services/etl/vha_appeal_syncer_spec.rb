# frozen_string_literal: true

require_relative "./vha_shared_examples"

describe ETL::VhaAppealSyncer, :etl, :all_dbs do
  let(:origin_class) { Appeal }
  let(:target_class) { ETL::DecisionReview::Appeal }

  before do
    create(:request_issue, benefit_type: "vha")
    # we want a non-vha appeal to exist and be skipped.
    create(:request_issue, benefit_type: "foobar")
  end

  def vha_appeal_ids
    RequestIssue.select(:decision_review_id).where(benefit_type: "vha", decision_review_type: :Appeal)
  end

  def originals_count
    Appeal.where(id: vha_appeal_ids).count
  end

  include_examples "VHA decision review sync"

  describe "Appeal#call" do
    let(:etl_build) { ETL::Build.create }
    subject { described_class.new(etl_build: etl_build).call }

    context "Appeal is not yet established" do
      let!(:appeal) { create(:appeal, established_at: nil) }
      let(:etl_build_table) { ETL::BuildTable.find_by(table_name: "decision_reviews") }

      it "skips non-established Appeals" do
        subject

        expect(target_class.count).to eq(1)
        expect(etl_build_table.rows_rejected).to eq(0) # non-vha appeal is skipped by syncer query
        expect(etl_build_table.rows_inserted).to eq(1)
      end
    end
  end
end
