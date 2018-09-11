# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < AmaReview
  has_many :end_product_establishments, as: :source

  self.abstract_class = true

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
    end_product_establishments.each do |end_product_establishment|
      end_product_establishment.perform!
      create_contentions_for_end_product_establishment(end_product_establishment)
    end

    end_product_establishments.each(&:commit!)
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
    end
  end

  private

  def end_product_establishment_for_issue(issue)
    ep_code = issue_code(issue.rated?)
    end_product_establishments.find_by(code: ep_code) || new_end_product_establishment(ep_code)
  end

  def issue_code(_rated)
    fail Caseflow::Error::MustImplementInSubclass
  end

  def create_contentions_for_end_product_establishment(end_product_establishment)
    request_issues_without_contentions = request_issues.where(
      end_product_establishment: end_product_establishment,
      contention_reference_id: nil
    )

    return if request_issues_without_contentions.empty?

    end_product_establishment.create_contentions!(request_issues_without_contentions)
    create_associated_rated_issues!(end_product_establishment, request_issues_without_contentions)
  end

  def create_associated_rated_issues!(end_product_establishment, issues)
    request_issues_to_associate = issues.select(&:rated?)

    return if end_product_establishment.code != issue_code(true)
    return if request_issues_to_associate.empty?

    VBMSService.associate_rated_issues!(
      claim_id: end_product_establishment.reference_id,
      rated_issue_contention_map: rated_issue_contention_map(request_issues_to_associate)
    )

    RequestIssue.where(id: request_issues_to_associate.map(&:id)).update_all(
      rating_issue_associated_at: Time.zone.now
    )
  end

  def rated_issue_contention_map(request_issues_to_associate)
    request_issues_to_associate.inject({}) do |contention_map, issue|
      contention_map[issue.rating_issue_reference_id] = issue.contention_reference_id
      contention_map
    end
  end

  def sync_dispositions(reference_id)
    fetch_dispositions_from_vbms(reference_id).each do |disposition|
      matching_request_issue(disposition[:contention_id]).update!(disposition: disposition[:disposition])
    end
  end

  def fetch_dispositions_from_vbms(reference_id)
    VBMSService.get_dispositions!(claim_id: reference_id)
  end

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end
end
