# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < DecisionReview
  has_many :end_product_establishments, as: :source
  has_one :intake, as: :detail

  with_options if: :saving_review do
    validates :receipt_date, :benefit_type, presence: { message: "blank" }
    validates :veteran_is_not_claimant, inclusion: { in: [true, false], message: "blank" }
    validates_associated :claimants
  end

  validates :legacy_opt_in_approved, inclusion: {
    in: [true, false], message: "blank"
  }, if: [:legacy_opt_in_enabled?, :saving_review]

  self.abstract_class = true

  class NoEndProductsRequired < StandardError; end

  class << self
    def find_by_uuid_or_reference_id!(claim_id)
      claim_review = find_by(uuid: claim_id) ||
                     EndProductEstablishment.find_by(reference_id: claim_id, source_type: to_s).try(:source)
      fail ActiveRecord::RecordNotFound unless claim_review

      claim_review
    end
  end

  def ui_hash
    super.merge(
      benefitType: benefit_type,
      payeeCode: payee_code,
      hasClearedEP: cleared_ep?
    )
  end

  def caseflow_only_edit_issues_url
    "/#{self.class.to_s.underscore.pluralize}/#{uuid}/edit"
  end

  def issue_code(*)
    fail Caseflow::Error::MustImplementInSubclass
  end

  # Save issues and assign it the appropriate end product establishment.
  # Create that end product establishment if it doesn't exist.
  def create_issues!(new_issues)
    new_issues.each do |issue|
      if caseflow_only?
        issue.update!(benefit_type: benefit_type, veteran_participant_id: veteran.participant_id)
      else
        issue.update!(
          end_product_establishment: end_product_establishment_for_issue(issue),
          benefit_type: benefit_type,
          veteran_participant_id: veteran.participant_id
        )
      end
      issue.create_legacy_issue_optin if issue.legacy_issue_opted_in?
    end
    request_issues.reload
  end

  def create_decision_review_task!
    return if tasks.any? { |task| task.is_a?(DecisionReviewTask) } # TODO: more specific check?

    DecisionReviewTask.create!(appeal: self, assigned_at: Time.zone.now, assigned_to: business_line)
  end

  def business_line
    return unless caseflow_only?

    business_line_name = Constants::BENEFIT_TYPES[benefit_type]
    fail "No such business line: #{benefit_type}" unless business_line_name

    @business_line ||= BusinessLine.find_or_create_by(url: benefit_type, name: business_line_name)
  end

  # Idempotent method to create all the artifacts for this claim.
  # If any external calls fail, it is safe to call this multiple times until
  # establishment_processed_at is successfully set.
  def establish!
    attempted!

    if caseflow_only? && end_product_establishments.any?
      fail NoEndProductsRequired, message: "Non-comp decision reviews should not have End Products"
    end

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

    process_legacy_issues!

    clear_error!
    processed!
  end

  def invalid_modifiers
    end_product_establishments.map(&:modifier).reject(&:nil?)
  end

  def rating_end_product_establishment
    @rating_end_product_establishment ||= end_product_establishments.find_by(
      code: self.class::END_PRODUCT_CODES[:rating]
    )
  end

  def end_product_description
    rating_end_product_establishment&.description
  end

  def end_product_base_modifier
    valid_modifiers.first
  end

  def valid_modifiers
    self.class::END_PRODUCT_MODIFIERS
  end

  def on_sync(end_product_establishment)
    if end_product_establishment.status_cleared?
      end_product_establishment.sync_decision_issues!
      # allow higher level reviews to do additional logic on dta errors
      yield if block_given?
    end
  end

  def cleared_ep?
    end_product_establishments.any? { |ep| ep.status_cleared?(sync: true) }
  end

  def find_request_issue_by_description(description)
    request_issues.find { |reqi| reqi.description == description }
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

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end
end
