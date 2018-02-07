class VACOLS::CaseDecision < VACOLS::Record
  self.table_name = "vacols.decass"
  self.primary_key = "defolder"

  has_one :case, foreign_key: :bfkey

  # :nocov:
  class << self
    def find_by_vacols_id_and_css_id(css_id, vacols_id)
      css_id = connection.quote(css_id.upcase)
      vacols_id = connection.quote(vacols_id)

      where(defolder: vacols_id)
        .where(decomp: nil)
        .where("staff.sdomainid = #{css_id}")
        .joins("join brieff on brieff.bfkey = decass.defolder")
        .joins("join staff on brieff.bfcurloc = staff.slogid")
        .first
    end
  end

  def reassign_case_to_judge!(decision_info)
    attrs = decision_info.each_with_object({}) { |(k, v), result| result[COLUMN_NAMES[k]] = v }
    MetricsService.record("VACOLS: update_case_decision! #{defolder}",
                          service: :vacols,
                          name: "update_case_decision") do
      update(attrs)
    end
  end
  # :nocov:
end
