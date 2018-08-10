# A model that centralizes all information
# about the appellant's legal representation.
#
# Power of attorney (also referred to as "representative")
# is tied to the appeal in VACOLS, but it's tied to the veteran
# in BGS - so the two are ofen out of sync.
# This class exposes information from both systems
# and lets the user modify VACOLS with BGS information
# (but not the other way around).
class PowerOfAttorney
  include ActiveModel::Model
  include AssociatedVacolsModel

  vacols_attr_accessor  :vacols_representative_type,
                        :vacols_first_name,
                        :vacols_middle_initial,
                        :vacols_last_name,
                        :vacols_suffix,
                        :vacols_org_name

  attr_accessor :vacols_id,
                :file_number

  # By using the prefix command of delegate we make the methods bgs_representative_name etc.
  delegate :representative_name,
           :representative_type,
           :representative_address,
           :participant_id, to: :bgs_power_of_attorney, prefix: :bgs

  def update_vacols_rep_info!(appeal:, representative_type:, representative_name:, address:)
    repo = self.class.repository
    vacols_code = repo.get_vacols_rep_code_from_poa(representative_type, representative_name)

    # Update the BRIEFF table.
    repo.update_vacols_rep_type!(
      case_record: appeal.case_record,
      vacols_rep_type: vacols_code
    )

    # If the POA should be stored in the REP table, update that too.
    if repo.rep_name_found_in_rep_table?(vacols_code)
      rep_type = :appellant_attorney if vacols_code == "T"
      rep_type = :appellant_agent if vacols_code == "U"

      repo.update_vacols_rep_table!(
        appeal: appeal,
        representative_name: representative_name,
        address: address,
        rep_type: rep_type
      )
    end
  end

  def vacols_representative_name
    return vacols_org_name unless vacols_org_name.empty?
    "#{vacols_first_name} #{vacols_middle_initial} #{vacols_last_name} #{vacols_suffix}".strip
  end

  private

  def bgs_power_of_attorney
    @bgs_poa ||= BgsPowerOfAttorney.new(file_number: file_number)
  end

  class << self
    attr_writer :repository

    def repository
      return PowerOfAttorneyRepository if FeatureToggle.enabled?(:test_facols)
      @repository ||= PowerOfAttorneyRepository
    end
  end
end
