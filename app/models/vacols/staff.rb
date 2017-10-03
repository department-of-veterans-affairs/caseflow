class VACOLS::Staff < VACOLS::Record
  self.table_name = "vacols.staff"
  self.primary_key = "stafkey"

  class << self
    def number_of_slots(ro:, type:, date:)
      record = find_by(stafkey: ro)
      return unless record
      record.slots_based_on_type(type, date)
    end
  end

  def slots_based_on_type(type, date)
    case type
    when :central_office
      11
    when :video
      stc4
    when :travel
      (date.monday? || date.friday?) ? stc2 : stc3
    end
  end
end
