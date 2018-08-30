module QueueMapper
  COLUMN_NAMES = {
    work_product: :deprod,
    note: :deatcom,
    document_id: :dedocid,
    modifying_user: :demdusr,
    reassigned_to_judge_date: :dereceive,
    assigned_to_attorney_date: :deassign,
    deadline_date: :dedeadline,
    attorney_id: :deatty,
    group_name: :deteam,
    board_member_id: :dememid,
    complexity: :defdiff,
    quality: :deoq,
    comment: :debmcom,
    completion_date: :decomp,
    timeliness: :detrem
  }.freeze

  DEFICIENCIES = {
    issues_are_not_addressed: :deqr1,
    theory_contention: :deqr2,
    caselaw: :deqr3,
    statue_regulation: :deqr4,
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

  def self.rename_and_validate_decass_attrs(decass_attrs)
    update_attrs = COLUMN_NAMES.keys.each_with_object({}) do |k, result|
      # skip only if the key is not passed, if the key is passed and the value is nil - include that
      next unless decass_attrs.keys.include? k
      result[COLUMN_NAMES[k]] = case k
                                when :work_product
                                  work_product_to_vacols_code(decass_attrs[:work_product], decass_attrs[:overtime])
                                when :complexity
                                  complexity_to_vacols_code(decass_attrs[:complexity])
                                when :quality
                                  quality_to_vacols_code(decass_attrs[:quality])
                                else
                                  decass_attrs[k]
                                end
      result
    end

    update_attrs.merge(rename_deficiencies(decass_attrs[:deficiencies]))
      .merge(demdtim: VacolsHelper.local_date_with_utc_timezone)
  end

  def self.rename_deficiencies(deficiencies)
    (deficiencies || []).each_with_object({}) do |d, result|
      result[DEFICIENCIES[d.to_sym]] = "Y"
      result
    end
  end

  def self.complexity_to_vacols_code(complexity)
    result = COMPLEXITY.key(complexity.to_sym)
    fail Caseflow::Error::QueueRepositoryError, "Complexity value is not valid" unless result
    result
  end

  def self.quality_to_vacols_code(quality)
    result = QUALITY.key(quality.to_sym)
    fail Caseflow::Error::QueueRepositoryError, "Quality value is not valid" unless result
    result
  end

  def self.work_product_to_vacols_code(work_product, overtime)
    overtime ? OVERTIME_WORK_PRODUCTS.key(work_product) : WORK_PRODUCTS.key(work_product)
  end
end
