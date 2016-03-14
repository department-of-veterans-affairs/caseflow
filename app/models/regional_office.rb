class RegionalOffice
  include ActiveModel::Model

  attr_accessor :ro_id
  attr_accessor :city, :state

  def caseflow?
    return false
  end

  class << self
    attr_writer :repository
    delegate :certify, to: :repository

    def find(ro_id)
      unless (office = repository.find(ro_id))
        fail ActiveRecord::RecordNotFound
      end
      office
    end

    def all()
      repository.all()
    end

    def repository
      @repository ||= RegionalOfficeRepository
    end

    def from_record(office_record:)
      ro_id = office_record.stafkey
      location = Records::RegionalOffice::CITIES[ro_id] || {} 

      new(
        ro_id: ro_id,
        city: location[:city],
        state: location[:state],
      )
    end
  end
end
