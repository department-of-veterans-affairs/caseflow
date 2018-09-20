# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < AmaReview
  has_many :end_product_establishments, as: :source

  self.abstract_class = true

  class << self
    def rated_issue_code
      self::END_PRODUCT_RATING_CODE
    end

    def nonrated_issue_code
      self::END_PRODUCT_NONRATING_CODE
    end
  end

  # Save issues and assign it the appropriate end product establishment.
  # Create that end product establishment if it doesn't exist.
  def create_issues!(new_issues)
    new_issues.each do |issue|
      issue.update!(end_product_establishment: end_product_establishment_for_issue(issue))
    end
  end

  # Send the appropriate calls to VBMS to create the end products and contentions for any
  # outstanding end product establishment. If all end products have been created then this
  # method does nothing
  def process_end_product_establishments!
    return if establishment_processed_at

    end_product_establishments.each do |end_product_establishment|
      end_product_establishment.perform!
      create_contentions_for_end_product_establishment(end_product_establishment)
    end

    end_product_establishments.each(&:commit!)
    update!(establishment_processed_at: Time.zone.now)
  end

  # NOTE: Choosing not to test this method because it is fully tested in RequestIssuesUpdate.perform!
  # Hoping to figure out how to refactor this into a private method.
  def on_request_issues_update!(request_issues_update)
    process_end_product_establishments!

    request_issues_update.removed_issues.each do |request_issue|
      request_issue.end_product_establishment.remove_contention!(request_issue)
    end
  end

  def invalid_modifiers
    end_product_establishments.map(&:modifier).reject(&:nil?)
  end

  def on_sync(end_product_establishment)
    if end_product_establishment.status_cleared?
      sync_dispositions(end_product_establishment.reference_id)
      # allow higher level reviews to do additional logic on dta errors
      yield if block_given?
    end
  end

  private

  def end_product_establishment_for_issue(issue)
    ep_code = issue.rated? ? self.class.rated_issue_code : self.class.nonrated_issue_code
    end_product_establishments.find_by(code: ep_code) || new_end_product_establishment(ep_code)
  end

  def create_contentions_for_end_product_establishment(end_product_establishment)
    request_issues_without_contentions = request_issues.where(
      end_product_establishment: end_product_establishment,
      contention_reference_id: nil
    )

    end_product_establishment.create_contentions!(request_issues_without_contentions)
    end_product_establishment.create_associated_rated_issues!
  end

  def sync_dispositions(reference_id)
    fetch_dispositions_from_vbms(reference_id).each do |disposition|
      request_issue = matching_request_issue(disposition[:contention_id])
      request_issue.update!(disposition: disposition[:disposition])
      # allow higher level reviews to do additional logic on dta errors
      yield(disposition, request_issue) if block_given?
    end
  end

  def fetch_dispositions_from_vbms(reference_id)
    VBMSService.get_dispositions!(claim_id: reference_id)
  end

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end
end
