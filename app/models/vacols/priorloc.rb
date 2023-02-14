# frozen_string_literal: true

class VACOLS::Priorloc < VACOLS::Record
  self.table_name = "priorloc"
  self.primary_key = "lockey"

  attribute :locdin, :datetime
  attribute :locdout, :datetime
  attribute :locdto, :datetime

  def sub_location
    loclcode
  end

  def folder
    lockey
  end

  alias vacols_id folder

  def location_date_in
    locdin
  end

  # mapping for frontend so can look similar to tasks
  alias closed_at location_date_in

  def location_date_out
    locdout
  end

  # mapping for frontend so can look similar to tasks
  alias created_at location_date_out

  def location
    locstto
  end

  def location_label
    return location unless /[0-9]+/.match?(location)

    label = staff&.snamel
    return label if label.present?

    location
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

  def staff
    @staff ||= VACOLS::Staff.find_by(slogid: location)
  end

  def location_user
    @location_user ||= User.where(css_id: staff&.sdomainid)&.first
  end

  def with_attorney?
    location_user&.attorney? || false
  end

  def with_judge?
    location_user&.judge? || false
  end

  def summary
    {
      assigned_by: assigned_by,
      assigned_at: assigned_at,
      location: location,
      sub_location: sub_location,
      location_staff: location_staff,
      date_out: location_date_out,
      date_in: location_date_in,
      vacols_id: vacols_id,
      exception_flag: exception_flag,
      with_attorney?: with_attorney?,
      with_judge?: with_judge?
    }
  end
end
