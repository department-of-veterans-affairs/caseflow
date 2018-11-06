# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < DecisionReview
  include Asyncable

  has_many :end_product_establishments, as: :source
  has_one :intake, as: :detail

  self.abstract_class = true

  def ui_hash
    super.merge(
      benefitType: benefit_type,
      payeeCode: payee_code,
      hasClearedEP: cleared_ep?
    )
  end

  # The Asyncable module requires we define these.
  # establishment_submitted_at - when our db is ready to push to exernal services
  # establishment_attempted_at - when our db attempted to push to external services
  # establishment_processed_at - when our db successfully pushed to external services

  class << self
    def submitted_at_column
      :establishment_submitted_at
    end

    def attempted_at_column
      :establishment_attempted_at
    end

    def processed_at_column
      :establishment_processed_at
    end

    def error_column
      :establishment_error
    end
  end

  def issue_code(*)
    fail Caseflow::Error::MustImplementInSubclass
  end

  # Save issues and assign it the appropriate end product establishment.
  # Create that end product establishment if it doesn't exist.
  def create_issues!(new_issues)
    new_issues.each do |issue|
      issue.update!(end_product_establishment: end_product_establishment_for_issue(issue))
    end
  end

  # Idempotent method to create all the artifacts for this claim.
  # If any external calls fail, it is safe to call this multiple times until
  # establishment_processed_at is successfully set.
  def process_end_product_establishments!
    attempted!

    end_product_establishments.each do |end_product_establishment|
      end_product_establishment.perform!
      end_product_establishment.create_contentions!
      end_product_establishment.associate_rating_request_issues!
      if informal_conference?
        end_product_establishment.generate_claimant_letter!
        end_product_establishment.generate_tracked_item!
      end
      end_product_establishment.commit!
    end

    clear_error!
    processed!
  end

  def invalid_modifiers
    end_product_establishments.map(&:modifier).reject(&:nil?)
  end

  def on_sync(end_product_establishment)
    if end_product_establishment.status_cleared?
      sync_dispositions(end_product_establishment.reference_id)
      veteran.sync_rating_issues!(end_product_establishment.active_request_issues)
      # allow higher level reviews to do additional logic on dta errors
      yield if block_given?
    end
  end

  def cleared_ep?
    end_product_establishments.any? { |ep| ep.status_cleared?(sync: true) }
  end

  private

  def informal_conference?
    false
  end

  def intake_processed_by
    intake ? intake.user : nil
  end

  def end_product_establishment_for_issue(issue)
    ep_code = issue_code(rating: (issue.rating? || issue.is_unidentified?))
    end_product_establishments.find_by(code: ep_code) || new_end_product_establishment(ep_code)
  end

  def sync_dispositions(reference_id)
    fetch_dispositions_from_vbms(reference_id).each do |disposition|
      matching_request_issue(disposition.contention_id).update!(
        disposition: disposition.disposition
      )
    end
  end

  def fetch_dispositions_from_vbms(reference_id)
    VBMSService.get_dispositions!(claim_id: reference_id)
  end

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end
end
