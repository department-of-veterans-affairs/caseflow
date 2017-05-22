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
                :file_number

  def load_bgs_record!
    result = bgs.fetch_poa_by_file_number(file_number)
    self.bgs_representative_name = result[:representative_name]
    self.bgs_representative_type = result[:representative_type]

    self
  end

  def overwrite_vacols_with_bgs_value
    # case_record.bfso
  end

  def bgs
    BGSService.new
  end

  class << self
    attr_writer :repository

    def repository
      @repository ||= PowerOfAttorneyRepository
    end
  end
end
