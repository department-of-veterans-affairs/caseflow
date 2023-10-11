# frozen_string_literal: true

class QueueMapper
  COLUMN_NAMES = {
    case_id: :defolder,
    work_product: :deprod,
    note: :deatcom,
    document_id: :dedocid,
    adding_user: :deadusr,
    modifying_user: :demdusr,
    added_at_date: :deadtim,
    reassigned_to_judge_date: :dereceive,
    assigned_to_attorney_date: :deassign,
    deadline_date: :dedeadline,
    attorney_id: :deatty,
    group_name: :deteam,
    board_member_id: :dememid,
    complexity_rating: :deicr,
    complexity: :defdiff,
    quality: :deoq,
    comment: :debmcom,
    completion_date: :decomp,
    timeliness: :detrem,
    one_touch_initiative: :de1touch,
    deteam: :deteam
  }.freeze

  DEFICIENCIES = {
    issues_are_not_addressed: :deqr1,
    theory_contention: :deqr2,
    caselaw: :deqr3,
    statute_regulation: :deqr4,
    admin_procedure: :deqr5,
    relevant_records: :deqr6,
    lay_evidence: :deqr7,
    findings_are_not_supported: :deqr8,
    process_violations: :deqr9,
    remands_are_not_completed: :deqr10,
    grammar_errors: :deqr11
  }.freeze

  QUALITY = {
    "5" => :outstanding,
    "4" => :exceeds_expectations,
    "3" => :meets_expectations,
    "2" => :needs_improvements,
    "1" => :does_not_meet_expectations
  }.freeze

  COMPLEXITY = {
    "3" => :hard,
    "2" => :medium,
    "1" => :easy
  }.freeze

  WORK_PRODUCTS = {
    "DEC" => "Decision",
    "IME" => "OMO - IME",
    "VHA" => "OMO - VHA"
  }.freeze

  OVERTIME_WORK_PRODUCTS = {
    "OTD" => "Decision",
    "OTI" => "OMO - IME",
    "OTV" => "OMO - VHA"
  }.freeze

  def initialize(decass_attrs)
    @decass_attrs = decass_attrs
  end

  def rename_and_validate_decass_attrs
    transform_the_data

    renamed_attributes
  end

  private

  attr_reader :decass_attrs

  def transform_the_data
    convert_work_product_to_vacols_code
    convert_complexity_to_vacols_code
    convert_quality_to_vacols_code
    convert_one_touch_initiative_to_vacols_code
    convert_deficiencies_to_vacols_code
    assign_note_and_comment
    add_modification_timestamp
  end

  def convert_work_product_to_vacols_code
    return unless work_product

    renamed_attributes[COLUMN_NAMES[:work_product]] = work_product_to_vacols_code
  end

  def convert_complexity_to_vacols_code
    return unless complexity

    renamed_attributes[COLUMN_NAMES[:complexity]] = complexity_to_vacols_code
  end

  def convert_quality_to_vacols_code
    return unless quality

    renamed_attributes[COLUMN_NAMES[:quality]] = quality_to_vacols_code
  end

  def convert_one_touch_initiative_to_vacols_code
    return unless decass_attrs.key?(:one_touch_initiative)

    renamed_attributes[COLUMN_NAMES[:one_touch_initiative]] = one_touch_initiative_to_vacols_code
  end

  def convert_deficiencies_to_vacols_code
    (deficiencies || []).each do |deficiency|
      renamed_attributes[DEFICIENCIES[deficiency.to_sym]] = "Y"
    end
  end

  def assign_note_and_comment
    renamed_attributes[COLUMN_NAMES[:note]] = note if note
    renamed_attributes[COLUMN_NAMES[:comment]] = comment if comment
  end

  def add_modification_timestamp
    renamed_attributes[:demdtim] = VacolsHelper.local_date_with_utc_timezone
  end

  def renamed_attributes
    @renamed_attributes ||= begin
      COLUMN_NAMES.keys.each_with_object({}) do |key, result|
        # Skip only if the key is not passed. If the key is passed and the value is nil, include it.
        next unless decass_attrs.key?(key)

        result[COLUMN_NAMES[key]] = decass_attrs[key]
        result
      end
    end
  end

  def work_product_to_vacols_code
    overtime ? OVERTIME_WORK_PRODUCTS.key(work_product) : WORK_PRODUCTS.key(work_product)
  end

  def complexity_to_vacols_code
    result = COMPLEXITY.key(complexity.to_sym)
    fail Caseflow::Error::QueueRepositoryError, "Complexity value is not valid" unless result

    result
  end

  def quality_to_vacols_code
    result = QUALITY.key(quality.to_sym)
    fail Caseflow::Error::QueueRepositoryError, "Quality value is not valid" unless result

    result
  end

  def one_touch_initiative_to_vacols_code
    one_touch_initiative ? "Y" : "N"
  end

  def work_product
    decass_attrs[:work_product]
  end

  def overtime
    decass_attrs[:overtime]
  end

  def complexity
    decass_attrs[:complexity]
  end

  def quality
    decass_attrs[:quality]
  end

  def deficiencies
    decass_attrs[:deficiencies]
  end

  def one_touch_initiative
    decass_attrs[:one_touch_initiative]
  end

  def note
    decass_attrs[:note]
  end

  def comment
    decass_attrs[:comment]
  end
end
