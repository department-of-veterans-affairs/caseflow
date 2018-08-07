class Appeal < AmaReview
  has_many :appeal_views, as: :appeal
  has_many :claims_folder_searches, as: :appeal
  has_many :tasks, as: :appeal
  has_many :decision_issues, through: :request_issues

  validates :receipt_date, :docket_type, presence: { message: "blank" }, on: :intake_review

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

  def type
    "Original"
  end

  def docket_name
    docket_type
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

  def create_issues!(request_issues_data:)
    request_issues.destroy_all unless request_issues.empty?

    request_issues_data.map { |data| request_issues.create_from_intake_data!(data) }
  end

  def serializer_class
    ::WorkQueue::AppealSerializer
  end

  def docket_number
    "#{established_at.strftime('%y%m%d')}-#{id}"
  end

  def power_of_attorney
    @bgs_poa ||= BgsPowerOfAttorney.new(file_number: veteran_file_number)
  end

  delegate :representative_name, :representative_type, :representative_address, to: :power_of_attorney

  def external_id
    uuid
  end
end
