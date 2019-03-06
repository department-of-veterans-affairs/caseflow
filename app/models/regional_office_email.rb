# frozen_string_literal: true

class RegionalOfficeEmail
  include ActiveModel::Model
  attr_accessor :recipient, :ro_id

  def ro_name
    ro_city ? "#{ro_city[:city]}, #{ro_city[:state]}" : "Unknown"
  end

  private

  def ro_city
    @ro_city ||= RegionalOffice::CITIES[ro_id]
  end
end
