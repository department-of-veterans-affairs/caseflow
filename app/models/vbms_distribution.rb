# frozen_string_literal: true

class VbmsDistribution < CaseflowRecord
  # Changed this association to "belongs_to" instead of "has_one" because FK sits on this table. Is that correct?
  belongs_to :vbms_communication_package, optional: false
  # has_one :vbms_communication_package
  has_one :vbms_distribution_destination

  validates :recipient_type, presence: true, inclusion: { in: %w(organization person system ro-colocated)}
  validates :first_name, :last_name, presence: true, if: :is_person?
  validates :name, presence: true, unless: :is_person?
  validates :poa_code, :claimant_station_of_jurisdiction, presence: true, if: :is_ro_colocated?

  def is_person?
    recipient_type == "person"
  end

  def is_ro_colocated?
    recipient_type == "ro-colocated"
  end

end
