class VACOLS::CaseAssignment < VACOLS::Record
  self.table_name = "vacols.brieff"

  has_one :staff, foreign_key: :slogid, primary_key: :bfcurloc
  has_one :case_decision, foreign_key: :defolder, primary_key: :bfkey
  has_one :correspondent, foreign_key: :stafkey, primary_key: :bfcorkey

  class << self
    def active_cases_for_user(css_id)
      id = connection.quote(css_id.upcase)

      select_assignments.where("staff.sdomainid = #{id}")
    end

    # Valid case assignments must have an associated staff table
    # so we perform an inner join on the staff table.
    # We would like to pull in the associated row in the correspondent
    # table to get the veteran's name, and the associated row in the
    # decass table to get the assigned dates, but these are not mandatory,
    # so we left join on both of them.
    def select_assignments
      select("brieff.bfkey as vacols_id",
             "decass.deassign as date_assigned",
             "decass.dereceive as date_received",
             "brieff.bfddec as signed_date",
             "brieff.bfcorlid as vbms_id",
             "corres.snamef as veteran_first_name",
             "corres.snamemi as veteran_middle_initial",
             "corres.snamel as veteran_last_name")
        .joins(<<-SQL)
          LEFT JOIN decass
            ON brieff.bfkey = decass.defolder
          LEFT JOIN corres
            ON brieff.bfcorkey = corres.stafkey
          JOIN staff
            ON brieff.bfcurloc = staff.slogid
        SQL
    end
  end
end
