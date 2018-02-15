class VACOLS::CaseDecision < VACOLS::Record
  self.table_name = "vacols.decass"
  self.primary_key = "defolder"

  has_one :case, foreign_key: :bfkey

  COLUMN_NAMES = {
    work_product: :deprod,
    note: :deatcom,
    document_id: :dedocid,
    reassigned_at: :dereceive
  }.freeze

  # :nocov:
  class << self
    def find_by_vacols_id_and_css_id(vacols_id, css_id)
      css_id = connection.quote(css_id.upcase)

      where(defolder: vacols_id)
        .where(decomp: nil)
        .where("staff.sdomainid = #{css_id}")
        .joins("join brieff on brieff.bfkey = decass.defolder")
        .joins("join staff on brieff.bfcurloc = staff.slogid")
        .first
    end
  end

  def update_case_decision!(decision_info)
    attrs = decision_info.each_with_object({}) { |(k, v), result| result[COLUMN_NAMES[k]] = v }
    MetricsService.record("VACOLS: update_case_decision! #{defolder}",
                          service: :vacols,
                          name: "update_case_decision") do
      update(attrs)
    end
  end
  # :nocov:
end
