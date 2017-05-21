# The appellant's legal representation for the appeal.

class PowerOfAttorney
  include ActiveModel::Model
  include AssociatedVacolsModel

  vacols_attr_accessor vacols_representative_type
  vacols_attr_accessor vacols_representative_name

  attr_accessor bgs_representative_name,
                bgs_representative_type,
                vacols_id,
                case_record,
                file_number

  def fetch_bgs_info!(file_number)
    result = self.class.bgs.fetch_poa_by_file_number(file_number)
    # TODO: also fetch the address
    @bgs_representative_name = result[:representative_name]
    @bgs_representative_type = result[:representative_type]
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
      @repository ||= PoaRepository
    end

    def self.bgs
      BGSService.new
    end
  end
end
