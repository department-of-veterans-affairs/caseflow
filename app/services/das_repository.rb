class DasRepository
  def self.get_cases_assigned_to_user(user_id)
    VACOLS::Das.unsigned_cases_for_user(user_id).map do |assignment|
      {
        vacols_id: assignment.vacols_id,
        date_assigned: assignment.date_assigned,
        date_received: assignment.date_received,
        signed_date: assignment.signed_date
      }
    end
  end
end
