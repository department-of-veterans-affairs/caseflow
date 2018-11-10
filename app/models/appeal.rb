class Appeal < DecisionReview
  include Taskable

  has_many :appeal_views, as: :appeal
  has_many :claims_folder_searches, as: :appeal
  has_many :tasks, as: :appeal
  has_many :decision_issues, through: :request_issues
  has_many :decisions
  has_one :special_issue_list

  with_options on: :intake_review do
    validates :receipt_date, :docket_type, presence: { message: "blank" }
    validates :legacy_opt_in_approved, inclusion: { in: [true, false], message: "blank" }, if: :legacy_opt_in_enabled?
  end

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/

  def document_fetcher
    @document_fetcher ||= DocumentFetcher.new(
      appeal: self, use_efolder: true
    )
  end

  delegate :documents, :number_of_documents, :manifest_vbms_fetched_at,
           :new_documents_for_user, :manifest_vva_fetched_at, to: :document_fetcher

  def self.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(id)
    if UUID_REGEX.match(id)
      find_by_uuid!(id)
    else
      LegacyAppeal.find_or_create_by_vacols_id(id)
    end
  end

  def ui_hash
    super.merge(
      docketType: docket_type,
      formType: "appeal"
    )
  end

  def type
    "Original"
  end

  def attorney_case_reviews
    tasks.map(&:attorney_case_reviews).flatten
  end

  def reviewing_judge_name
    task = tasks.where(type: "JudgeTask").order(:created_at).last
    task ? task.assigned_to.try(:full_name) : ""
  end

  def eligible_request_issues
    request_issues.select(&:eligible?)
  end

  def issues
    { decision_issues: decision_issues, request_issues: request_issues }
  end

  def docket_name
    docket_type
  end

  def decision_date
    decisions.last.try(:decision_date)
  end

  def hearing_docket?
    docket_type == "hearing"
  end

  def evidence_submission_docket?
    docket_type == "evidence_submission"
  end

  def direct_review_docket?
    docket_type == "direct_review"
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  def veteran_name
    # For consistency with LegacyAppeal.veteran_name
    veteran && veteran.name.formatted(:form)
  end

  def veteran_full_name
    veteran && veteran.name.formatted(:readable_full)
  end

  def veteran_middle_initial
    veteran && veteran.name.middle_initial
  end

  def veteran_is_deceased
    veteran_death_date.present?
  end

  def veteran_death_date
    veteran && veteran.date_of_death
  end

  delegate :address_line_1,
           :address_line_2,
           :address_line_3,
           :city,
           :state,
           :zip,
           :gender,
           :date_of_birth,
           :country, to: :veteran, prefix: true

  def regional_office
    nil
  end

  def advanced_on_docket
    claimants.any? { |claimant| claimant.advanced_on_docket(receipt_date) }
  end

  delegate :first_name, :last_name, :name_suffix, :ssn, to: :veteran, prefix: true, allow_nil: true

  def number_of_issues
    issues[:request_issues].size
  end

  def appellant
    claimants.first
  end

  def payee_code_required?
    false
  end

  delegate :first_name, :last_name, :middle_name, :name_suffix, to: :appellant, prefix: true, allow_nil: true

  def cavc
    "not implemented for AMA"
  end

  def status
    nil
  end

  def previously_selected_for_quality_review
    "not implemented for AMA"
  end

  def create_issues!(new_issues)
    new_issues.each(&:save!)
  end

  def serializer_class
    ::WorkQueue::AppealSerializer
  end

  def docket_number
    return "Missing Docket Number" unless receipt_date
    "#{receipt_date.strftime('%y%m%d')}-#{id}"
  end

  # For now power_of_attorney returns the first claimant's power of attorney
  def power_of_attorney
    claimants.first.power_of_attorney if claimants.first
  end
  delegate :representative_name, :representative_type, :representative_address, to: :power_of_attorney, allow_nil: true

  def power_of_attorneys
    claimants.map(&:power_of_attorney)
  end

  def vsos
    vso_participant_ids = power_of_attorneys.map(&:participant_id)
    Vso.where(participant_id: vso_participant_ids)
  end

  def external_id
    uuid
  end

  def create_tasks_on_intake_success!
    RootTask.create_root_and_sub_tasks!(self)
  end

  private

  def bgs
    BGSService.new
  end
end
