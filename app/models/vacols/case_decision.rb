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
        .joins(<<-SQL)
          JOIN brieff
            ON brieff.bfkey = decass.defolder
          JOIN staff
            ON brieff.bfcurloc = staff.slogid
        SQL
    end
  end

  def update_case_decision!()
  end
  # :nocov:
end
