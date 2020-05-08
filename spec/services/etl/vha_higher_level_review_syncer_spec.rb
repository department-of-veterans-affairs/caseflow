# frozen_string_literal: true

require_relative "./vha_shared_examples"

describe ETL::VhaHigherLevelReviewSyncer, :etl, :all_dbs do
  let(:origin_class) { HigherLevelReview }
  let(:target_class) { ETL::VhaHigherLevelReview }
  before do
    create(:higher_level_review)
    create(:higher_level_review, :processed)
    create(:higher_level_review, :processed, benefit_type: "vha")
  end

  def originals_count
    origin_class.where(benefit_type: "vha").count
  end

  include_examples "VHA decision review sync"
end
