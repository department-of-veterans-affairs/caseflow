class BgsPowerOfAttorney
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :file_number

  bgs_attr_accessor :representative_name, :representative_type, :participant_id

  def representative_address
    @bgs_representative_address ||= load_bgs_address!
  end

  private

  def bgs
    BGSService.new
  end

  def fetch_bgs_record
    bgs.fetch_poa_by_file_number(file_number)
  end

  def load_bgs_address!
    return nil if !participant_id

    begin
      return find_bgs_address
    rescue Savon::Error => e
      # If there is no address associated with the participant id,
      # Savon::SOAPFault will be thrown. Let's not reraise since
      # this error shouldn't block the user.

      # TODO: should this be an exception at all? It's a known case.
      # Fix ruby-bgs so it doesn't throw here.
      Raven.capture_exception(e)
    end

    nil
  end

  def find_bgs_address
    bgs.find_address_by_participant_id(participant_id)
  end
end
