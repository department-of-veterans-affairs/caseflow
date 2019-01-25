# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < DecisionReview
  include HasBusinessLine

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

    def find_all_by_file_number(file_number)
      HigherLevelReview.where(veteran_file_number: file_number) +
        SupplementalClaim.where(veteran_file_number: file_number)
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

  # Save issues and assign it the appropriate end product establishment.
  # Create that end product establishment if it doesn't exist.
  def create_issues!(new_issues)
    new_issues.each do |issue|
      if processed_in_caseflow?
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

  def create_decision_review_task_if_required!
    create_decision_review_task! if processed_in_caseflow?
  end

  # Idempotent method to create all the artifacts for this claim.
  # If any external calls fail, it is safe to call this multiple times until
  # establishment_processed_at is successfully set.
  def establish!
    attempted!

    if processed_in_caseflow? && end_product_establishments.any?
      fail NoEndProductsRequired, message: "Decision reviews processed in Caseflow should not have End Products"
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

  def search_table_ui_hash
    {
      caseflow_veteran_id: claim_veteran&.id,
      claim_id: id,
      veteran_file_number: veteran_file_number,
      veteran_full_name: claim_veteran&.name&.formatted(:readable_full),
      end_products: end_product_establishments,
      claimant_names: claimants.map(&:name).uniq, # We're not sure why we see duplicate claimants, but this helps
      review_type: self.class.to_s.underscore
    }
  end

  def claim_veteran
    Veteran.find_by(file_number: veteran_file_number)
  end

  private

  def can_contest_rating_issues?
    processed_in_vbms?
  end

  def create_decision_review_task!
    return if tasks.any? { |task| task.is_a?(DecisionReviewTask) } # TODO: more specific check?

    DecisionReviewTask.create!(appeal: self, assigned_at: Time.zone.now, assigned_to: business_line)
  end

  def informal_conference?
    false
  end

  def intake_processed_by
    intake ? intake.user : nil
  end

  def end_product_establishment_for_issue(issue)
    end_product_establishments.find_by(
      code: issue.end_product_code
    ) || new_end_product_establishment(issue.end_product_code)
  end

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end
end
