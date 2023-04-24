class VbmsDistrobution < ApplicationRecord

  belongs_to :vbms_communication_packages
  has_many :vbms_distribution_destinations

end
