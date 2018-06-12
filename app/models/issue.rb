# Note: The vacols_sequence_id column maps to the ISSUE table ISSSEQ column in VACOLS
# Using this and the appeal's vacols_id, we can directly map a Caseflow issue back to its
# VACOLS' equivalent
class Issue
  include ActiveModel::Model
  include ActiveModel::Serialization

  attr_accessor :id, :vacols_sequence_id, :codes, :disposition,
                :disposition_id, :readable_disposition, :close_date, :note

  # Labels are only loaded if we run the joins to ISSREF and VFTYPES (see VACOLS::CaseIssue)
  attr_writer :labels
  def labels
    fail Caseflow::Error::AttributeNotLoaded if @labels == :not_loaded
    @labels
  end

  attr_writer :cavc_decisions
  def cavc_decisions
    # This should probably always be preloaded to avoid each issue triggering an additional VACOLS query.
    @cavc_decisions ||= CAVCDecision.repository.cavc_decisions_by_issue(id, vacols_sequence_id)
  end

  PROGRAMS = {
    "01" => :vba_burial,
    "02" => :compensation,
    "03" => :education,
    "04" => :insurance,
    "05" => :loan_guaranty,
    "06" => :medical,
    "07" => :pension,
    "08" => :vre,
    "09" => :other,
    "10" => :bva,
    "11" => :nca_burial,
    "12" => :fiduciary
  }.freeze

  AOJ_FOR_PROGRAMS = {
    vba: [
      :vba_burial,
      :compensation,
      :education,
      :insurance,
      :loan_guaranty,
      :pension,
      :vre,
      :fiduciary
    ],
    vha: [
      :medical
    ],
    nca: [
      :nca_burial
    ]
  }.freeze

  def program
    PROGRAMS[codes[0]]
  end

  def aoj
    AOJ_FOR_PROGRAMS.keys.find do |type|
      AOJ_FOR_PROGRAMS[type].include?(program)
    end
  end

  def type
    labels[1]
  end

  def program_description
    "#{codes[0]} - #{labels[0]}"
  end

  def description
    codes[1..-1].zip(labels[1..-1]).map { |code, label| "#{code} - #{label}" }
  end

  def levels
    labels[2..-1] || []
  end

  def levels_with_codes
    codes[2..-1].zip(labels[2..-1]).map { |code, label| "#{code} - #{label}" }
  end

  def dic
    program == :compensation && codes[1] == "08"
  end

  def formatted_program_type_levels
    [
      [
        program.try(:capitalize),
        type
      ].compact.join(": ")
        .gsub(/Compensation/i, "Comp")
        .gsub(/Service Connection/i, "SC")
        .gsub(/Increased Rating/i, "IR"),
      levels_with_codes.join("; ")
    ].compact.join("\n")
  end

  def friendly_description
    friendly_description_for_codes(codes)
  end

  def friendly_description_without_new_material
    new_material? ? friendly_description_for_codes(%w[02 15 03]) : friendly_description
  end

  # returns "Remanded \n mm/dd/yyyy"
  def formatted_disposition
    [readable_disposition, close_date.try(:to_formatted_s, :short_date)].join("\n") if readable_disposition
  end

  def diagnostic_code
    codes.last if codes.last.length == 4
  end

  def category
    "#{codes[0]}-#{codes[1]}"
  end

  def type_hash
    codes.hash
  end

  def active?
    !disposition
  end

  def allowed?
    disposition == :allowed
  end

  def remanded?
    disposition == :remanded
  end

  def merged?
    disposition == :merged
  end

  # "New Material" (and "Non new material") are the exact
  # terms used internally by attorneys/judges. These mean the issue
  # was allowing/denying new material (such as medical evidence) to be used
  # in the appeal
  def new_material?
    codes[0..2] == %w[02 15 04]
  end

  def non_new_material?
    !new_material?
  end

  def non_new_material_allowed?
    non_new_material? && allowed?
  end

  def attributes
    {
      vacols_sequence_id: vacols_sequence_id,
      levels: levels,
      program: program,
      type: type,
      description: description,
      disposition: disposition,
      close_date: close_date,
      program_description: program_description,
      note: note
    }
  end

  def description_attributes
    {
      program_description: program_description,
      description: description,
      note: note
    }
  end

  attr_writer :remand_reasons
  def remand_reasons
    @remand_reasons ||= self.class.remand_repository.load_remands_from_vacols(id, vacols_sequence_id)
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  def friendly_description_for_codes(code_array)
    issue_description = code_array.reduce(Constants::ISSUE_INFO) do |levels, code|
      return nil unless levels[code]

      child_levels = levels[code]["levels"]

      unless child_levels
        description = levels[code]["plain_description"] || levels[code]["description"]
        break description if description.is_a?(String)
        return nil
      end

      child_levels
    end

    if diagnostic_code
      diagnostic_code_description = Constants::DIAGNOSTIC_CODE_DESCRIPTIONS[diagnostic_code]
      return if diagnostic_code_description.nil?
      # Some description strings are templates. This is a no-op unless the description string contains %s.
      issue_description = issue_description % diagnostic_code_description["status_description"]
    end

    issue_description
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  class << self
    attr_writer :repository

    def repository
      return IssueRepository if FeatureToggle.enabled?(:test_facols)
      @repository ||= IssueRepository
    end

    def remand_repository
      return RemandReasonRepository if FeatureToggle.enabled?(:test_facols)
      @remand_repository ||= RemandReasonRepository
    end

    def load_from_vacols(hash)
      disposition = nil
      if hash["issdc"]
        disposition = Constants::VACOLS_DISPOSITIONS_BY_ID[hash["issdc"]].parameterize.underscore.to_sym
      end
      new(
        id: hash["isskey"],
        vacols_sequence_id: hash["issseq"],
        codes: parse_codes_from_vacols(hash),
        labels: hash.key?("issprog_label") ? parse_labels_from_vacols(hash) : :not_loaded,
        note: hash["issdesc"],
        # disposition is a snake_case symbol, i.e. :remanded
        disposition: disposition,
        disposition_id: hash["issdc"] || nil,
        # readable disposition is a string, i.e. "Remanded"
        readable_disposition: Constants::VACOLS_DISPOSITIONS_BY_ID[hash["issdc"]],
        close_date: AppealRepository.normalize_vacols_date(hash["issdcls"])
      )
    end

    def create_in_vacols!(issue_attrs:)
      repository.create_vacols_issue!(issue_attrs: issue_attrs)
    end

    def update_in_vacols!(vacols_id:, vacols_sequence_id:, issue_attrs:)
      repository.update_vacols_issue!(
        vacols_id: vacols_id,
        vacols_sequence_id: vacols_sequence_id,
        issue_attrs: issue_attrs
      )
    end

    def delete_in_vacols!(vacols_id:, vacols_sequence_id:)
      repository.delete_vacols_issue!(
        vacols_id: vacols_id,
        vacols_sequence_id: vacols_sequence_id
      )
    end

    private

    def parse_codes_from_vacols(hash)
      [
        hash["issprog"],
        hash["isscode"],
        hash["isslev1"],
        hash["isslev2"],
        hash["isslev3"]
      ].compact
    end

    def parse_labels_from_vacols(hash)
      [
        hash["issprog_label"],
        hash["isscode_label"],
        hash["isslev1_label"],
        hash["isslev2_label"],
        hash["isslev3_label"]
      ].compact
    end
  end
end
