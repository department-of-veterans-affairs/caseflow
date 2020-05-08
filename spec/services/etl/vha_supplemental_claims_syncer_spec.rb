# frozen_string_literal: true

require_relative "./vha_shared_examples"

describe ETL::VhaSupplementalClaimSyncer, :etl, :all_dbs do
  let(:origin_class) { SupplementalClaim }
  let(:target_class) { ETL::VhaSupplementalClaim }
  before do
    create(:supplemental_claim)
    create(:supplemental_claim, benefit_type: "vha")
  end

  def originals_count
    origin_class.where(benefit_type: "vha").count
  end

  include_examples "VHA decision review sync"
end
