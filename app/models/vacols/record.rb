class VACOLS::Record < ActiveRecord::Base
  self.abstract_class = true

  establish_connection "#{Rails.env}_vacols"
end
