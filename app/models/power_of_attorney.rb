# A model that centralizes all information
# about the appellant's legal representation.
#
# Power of attorney (also referred to as "representative")
# is tied to the appeal in VACOLS, but it's tied to the veteran
# in BGS - so the two are ofen out of sync.
# This class exposes information from both systems
# and lets the user modify VACOLS with BGS information
# (but not the other way around).
#
# TODO: we query VACOLS when the vacols methods are
# called, even if we've also queried VACOLS outside of this
# model but in the same request. is this something we should optimize?
class PowerOfAttorney
  include ActiveModel::Model
  include AssociatedVacolsModel

  vacols_attr_accessor  :vacols_representative_type,
                        :vacols_representative_name

  attr_accessor :bgs_representative_name,
                :bgs_representative_type,
                :bgs_representative_address,
                :bgs_participant_id,
                :vacols_id,
                :file_number

  def load_bgs_record!
    result = bgs.fetch_poa_by_file_number(file_number)
    self.bgs_representative_name = result[:representative_name]
    self.bgs_representative_type = result[:representative_type]
    self.bgs_participant_id = result[:participant_id]
    self.bgs_representative_address = result[:participant_id] ? load_bgs_address! : nil

    self
  end

  def load_bgs_address!
    load_bgs_record! unless bgs_participant_id
    self.bgs_representative_address = nil

    begin
      self.bgs_representative_address = find_bgs_address
    rescue Savon::Error => e
      # If there is no address associated with the participant id,
      # Savon::SOAPFault will be thrown. Let's not reraise since
      # this error shouldn't block the user.

      # TODO: should this be an exception at all? It's a known case.
      # Fix ruby-bgs so it doesn't throw here.
      Raven.capture_exception(e)
    end

    bgs_representative_address
  end

  def overwrite_vacols_with_bgs_value
    # case_record.bfso
  end

  def update_vacols_rep_info!(appeal:, representative_type:, representative_name:, address:)
    repo = PowerOfAttorney.repository
    vacols_rep_type = if representative_type == "Service Organization" ||
                         representative_type == "ORGANIZATION"
                        # We set the rep type to the service organization name, unless we don't have a record
                        # of it. Then we set it to 'other'.
                        repo.get_vacols_rep_code(representative_name) ||
                          repo.get_vacols_rep_code("Other")
                      else
                        repo.get_vacols_rep_code(representative_type)
                      end
    repo.update_vacols_rep_type!(case_record: appeal.case_record, vacols_rep_type: vacols_rep_type)

    if repo.rep_name_found_in_rep_table?(vacols_rep_type)
      repo.update_vacols_rep_table!(appeal: appeal, representative_name: representative_name, address: address)
    end
  end

  private

  def find_bgs_address
    bgs.find_address_by_participant_id(bgs_participant_id)
  end

  def bgs
    @bgs ||= BGSService.new
  end

  class << self
    attr_writer :repository

    def repository
      @repository ||= PowerOfAttorneyRepository
    end
  end
end
