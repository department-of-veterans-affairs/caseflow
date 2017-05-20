# The appellant's legal representation for the appeal.

class PowerOfAttorney
  include ActiveModel::Model
  include AssociatedVacolsModel

  # fill this object out by hitting the findPOAs endpoint in BGS.
  BGS_TYPE_TO_VACOLS_VALUE = {
    "POA Attorney": "Attorney",
    "POA Agent": "Agent",
    "POA Local/Regional Organization": "Other Service Organization",
    "POA State Organization": "Other Service Organization"
  }.freeze

  vacols_attr_accessor vacols_representative_type
  # join on another

  attr_accessor bgs_representative_name
  attr_accessor bgs_representative_type

  def self.bgs
    BGSService.new
  end

  def self.reposistory
    POA
  end

  def join_tables
    # return representative
  end

  def fetch_bgs_info!(file_number)
    # result = self.class.bgs.fetch_poa_by_file_number(file_number)
    # bgs_representative_name = result[:power_of_attorney][:nm]
    # bgs_representative_type = result[:power_of_attorney][:org_type_nm]

    # also fetch the address
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
    #
  end

  class << self
    attr_writer :repository

    def repository
      @repository ||= PoaRepository
    end
  end
end
