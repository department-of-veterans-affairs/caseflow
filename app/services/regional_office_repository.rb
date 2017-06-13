class RegionalOfficeRepository
  def self.find(ro_id, _args = {})
    office_record = MetricsService.record("VACOLS: loaded RO #{ro_id}",
                                          service: :vacols,
                                          name: "RegionalOfficeRepository.find") do
      VACOLS::RegionalOffice.find(vacols_id)
    end
    office = RegionalOffice.from_record(office_record: office_record)
    office
  end

  def self.all(_args = {})
    ro_ids = VACOLS::RegionalOffice::ROS || []
    ros = MetricsService.record("VACOLS: loading all ROs",
                                service: :vacols,
                                name: "RegionalOfficeRepository.all") do
      VACOLS::RegionalOffice.where("STAFF.STAFKEY IN (?)", ro_ids)
    end
    ros.map { |v| RegionalOffice.from_record(office_record: v) }
  end
end
