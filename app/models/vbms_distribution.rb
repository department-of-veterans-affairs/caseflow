# frozen_string_literal: true

class VbmsDistribution < CaseflowRecord
  # Should this association be "belongs_to" instead of "has_one"? Because FK sits on this table
  belongs_to :vbms_communication_package, optional: false
  # has_one :vbms_communication_package
  has_one :vbms_distribution_destination

  validates :recipient_type, presence: true, inclusion: { in: %w(organization person system ro-colocated)}
  validates :name, presence: true, unless: :is_person?
  validates :first_name, presence: true, if: :is_person?
  validates :last_name, presence: true, if: :is_person?
  validates :poa_code, presence: true, if: :is_ro_colocated?
  validates :claimant_station_of_jurisdiction, presence: true, if: :is_ro_colocated?

  def is_person?
    recipient_type == "person"
  end

  def is_ro_colocated?
    recipient_type == "ro-colocated"
  end

end
