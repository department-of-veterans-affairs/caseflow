module RegionalOffice
  extend ActiveSupport::Concern

  def regional_office
    { key: regional_office_key }.merge(VACOLS::RegionalOffice::CITIES[regional_office_key] || {})
  end

  def regional_office_name
    "#{regional_office[:city]}, #{regional_office[:state]}"
  end
end
