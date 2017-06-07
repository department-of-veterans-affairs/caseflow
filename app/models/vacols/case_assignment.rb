class VACOLS::CaseAssignment < VACOLS::Record
  self.table_name = "vacols.decass"

  has_one :staff, foreign_key: :sattyid, primary_key: :deatty
  has_one :case, foreign_key: :bfkey, primary_key: :defolder

  class << self
    def unsigned_cases_for_user(vacols_user_id)
      id = connection.quote(vacols_user_id)

      select_assignments.where("staff.stafkey = #{id} and brieff.bfddec IS NULL")
    end

    def select_assignments
      select("defolder as vacols_id",
             "deassign as date_assigned",
             "dereceive as date_received",
             "staff.slogid as vacols_user_id",
             "brieff.bfddec as signed_date")
        .joins(:staff, :case)
    end
  end
end
