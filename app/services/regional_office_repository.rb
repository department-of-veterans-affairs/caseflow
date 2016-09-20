class RegionalOfficeRepository
  def self.find(ro_id, _args = {})
    office_record = MetricsService.timer "loaded RO #{ro_id}" do
      VACOLS::RegionalOffice.find(vacols_id)
    end
    office = RegionalOffice.from_record(office_record: office_record)
    office
  end

  def self.all(_args = {})
    ro_ids = VACOLS::RegionalOffice::ROS || []
    ros = MetricsService.timer "loading all ROs" do
      VACOLS::RegionalOffice.where("STAFF.STAFKEY IN (?)", ro_ids)
    end
    ros.map { |v| RegionalOffice.from_record(office_record: v) }
  end
end
