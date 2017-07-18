class VACOLS::CaseAssignment < VACOLS::Record
  self.table_name = "vacols.brieff"

  has_one :staff, foreign_key: :sattyid, primary_key: :deatty
  has_one :case_decision, foreign_key: :bfkey, primary_key: :defolder
  has_one :correspondent, foreign_key: :stafkey, primary_key: :bfcorkey

  class << self
    def active_cases_for_user(css_id)
      id = connection.quote(css_id.upcase)

      select_assignments.where("brieff.bfcurloc = staff.slogid and staff.sdomainid = #{id}")
    end

    def select_assignments
      select("decass.defolder as vacols_id",
             "decass.deassign as date_assigned",
             "decass.dereceive as date_received",
             "staff.slogid as vacols_user_id",
             "brieff.bfddec as signed_date",
             "brieff.bfcorlid as vbms_id",
             "corres.snamef as veteran_first_name",
             "corres.snamemi as veteran_middle_initial",
             "corres.snamel as veteran_last_name")
        .joins(:case_decision, :staff, :correspondent)
    end
  end
end
