# frozen_string_literal: true

class VACOLS::Priorloc < VACOLS::Record
  self.table_name = "priorloc"
  self.primary_key = "lockey"

  def assigned_at
    locdto
  end

  def location_date_in
    locdin
  end

  def location_date_out
    locdout
  end

  def location
    locstto
  end

  def assigned_by
    locstout
  end
end
