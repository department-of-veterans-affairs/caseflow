class RegionalOffice
  include ActiveModel::Model

  attr_accessor :ro_id
  attr_accessor :city, :state
  attr_accessor :caseflow_enabled

  def caseflow?
    @caseflow_enabled == "Y"
  end

  class << self
    attr_writer :repository
    delegate :all, to: :repository

    def find(ro_id)
      unless (office = repository.find(ro_id))
        fail ActiveRecord::RecordNotFound
      end
      office
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
        caseflow_enabled: office_record.sspare2
      )
    end
  end
end
