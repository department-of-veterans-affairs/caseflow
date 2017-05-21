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
# TODO: fetch POA address information from BGS
# TODO: fetch POA address information from VACOLS
# TODO: include the REP table in the VACOLS query and
# fetch representative name information from VACOLS
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
                :vacols_id,
                :case_record,
                :file_number

  def load_bgs_record!(file_number)
    result = self.class.bgs.fetch_poa_by_file_number(file_number)
    instance_variable_set(:bgs_representative_name, result[:representative_name])
    instance_variable_set(:bgs_representative_type, result[:representative_type])
  end

  def representative_matches_across_systems?
    # translate VACOLS and BGS values for representative name / type into a common format
    # and determine if they match.
    #
    # case_record.bfso
  end

  def address_matches_across_systems?
    # translate VACOLS and BGS values for address into a common format
    # and determine if they match.
  end

  def overwrite_vacols_with_bgs_value
    # case_record.bfso
  end

  class << self
    attr_writer :repository

    def repository
      @repository ||= PowerOfAttorneyRepository
    end

    def self.bgs
      BGSService.new
    end
  end
end
