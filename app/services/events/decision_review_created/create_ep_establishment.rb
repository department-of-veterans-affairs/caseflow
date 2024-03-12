# frozen_string_literal: true

class Events::DecisionReviewCreated::CreateEpEstablishment
  # The creation of End Product Establishment
  # claim_review can be either a supplemental claim or higher level review
  def process!(station_id, end_product_establishment, claim_review, user)
    end_product_establishment = EndProductEstablishment.find_or_create_by!(
      payee_code: end_product_establishment.payee_code,
      source: claim_review,
      veteran_file_number: claim_review.veteran_file_number,
      benefit_type_code: claim_review.benefit_type,
      claim_date: end_product_establishment.claim_date,
      code: end_product_establishment.code,
      committed_at: end_product_establishment.commited_at,
      established_at: end_product_establishment.established_at,
      last_synced_at: end_product_establishment.last_synced_at,
      limited_poa_access: end_product_establishment.limited_poa_access,
      limited_poa_code: end_product_establishment.limited_poa_code,
      modifier: end_product_establishment.modifier,
      reference_id: end_product_establishment.reference_id,
      station: station_id,
      synced_status: end_product_establishment.synced_status,
      user_id: user.id
    )
    end_product_establishment
  end
end
