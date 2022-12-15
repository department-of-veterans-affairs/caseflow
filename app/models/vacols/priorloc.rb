# frozen_string_literal: true

class VACOLS::Priorloc < VACOLS::Record
  self.table_name = "priorloc"
  self.primary_key = "lockey"

  def sub_location
    loclcode
  end

  def folder
    lockey
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

  def location_staff
    locstrcv
  end

  def assigned_by
    locstout
  end

  def exception_flag
    locexcep
  end

  def assigned_at
    locdto
  end

  def summary
    {
      assigned_by: assigned_by,
      assigned_at: assigned_at,
      location: location,
      sub_location: sub_location,
      location_staff: location_staff,
      date_in: location_date_in,
      date_out: location_date_out,
      folder: folder,
      exception_flag: exception_flag
    }
  end
end
