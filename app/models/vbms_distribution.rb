# frozen_string_literal: true

class VbmsDistribution < ApplicationRecord
  has_one :vbms_communication_package
  has_many :vbms_distribution_destinations
end
