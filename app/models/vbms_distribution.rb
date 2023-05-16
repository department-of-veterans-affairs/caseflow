# frozen_string_literal: true

class VbmsDistribution < CaseflowRecord
  belongs_to :vbms_communication_package, optional: false
  has_one :vbms_distribution_destination

  with_options presence: true do
    validates :recipient_type, inclusion: { in: %w(organization person system ro-colocated) }
    validates :first_name, :last_name, if: -> { recipient_type == "person" }
    validates :name, if: :is_not_a_person?
    validates :poa_code, :claimant_station_of_jurisdiction, if: -> { recipient_type == "ro-colocated" }
  end

  def is_not_a_person?
    %w(organization system ro-colocated).include?(recipient_type)
  end
end
