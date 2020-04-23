# frozen_string_literal: true

# A model that centralizes all information
# about the appellant's legal representation.
#
# Power of attorney (also referred to as "representative")
# is tied to the appeal in VACOLS, but it's tied to the veteran
# in BGS - so the two are often out of sync.
# This class exposes information from both systems
# and lets the user modify VACOLS with BGS information
# (but not the other way around).
#

class PowerOfAttorney
  include ActiveModel::Model
  include AssociatedVacolsModel
  include BgsService

  vacols_attr_accessor  :vacols_representative_type,
                        :vacols_representative_name,
                        :vacols_representative_address,
                        :vacols_representative_code

  attr_accessor :vacols_id,
                :file_number

  # By using the prefix command of delegate we make the methods bgs_representative_name etc.
  delegate :representative_name,
           :representative_type,
           :representative_address,
           :representative_email_address,
           :participant_id,
           to: :bgs_power_of_attorney, prefix: :bgs

  def update_vacols_rep_info!(appeal:, representative_type:, representative_name:, address:)
    repo = self.class.repository
    vacols_code = repo.get_vacols_rep_code_from_poa(representative_type, representative_name)

    # Update the BRIEFF table.
    repo.update_vacols_rep_type!(
      case_record: appeal.case_record,
      vacols_rep_type: vacols_code
    )

    # Update VACOLS with an attorney or agent we found from BGS.
    if representative_type == "Attorney" || representative_type == "Agent"
      rep_type = (representative_type == "Attorney") ? :appellant_attorney : :appellant_agent

      repo.update_vacols_rep_table!(
        appeal: appeal,
        rep_name: representative_name,
        address: address,
        rep_type: rep_type
      )
    end
  end

  private

  def bgs_power_of_attorney
    @bgs_power_of_attorney ||= BgsPowerOfAttorney.find_or_create_by_file_number(file_number)
  end

  class << self
    def repository
      PowerOfAttorneyRepository
    end
  end
end
