class Generators::Hearings::MasterRecord
  extend Generators::Base

  class << self
    def default_attrs
      {
        type: :video,
        date: Time.zone.now - 5.days,
        regional_office_key: VACOLS::RegionalOffice::CITIES.keys.sample,
        master_record: true
      }
    end

    def build(attrs = {})
      attrs[:user_id] ||= attrs[:user].try(:id) || Generators::User.create.id
      hearing = ::Hearing.new(default_attrs.merge(attrs))

      Fakes::HearingRepository.master_records ||= []
      date = hearing.date.to_date
      Fakes::HearingRepository.master_records.push(hearing) unless Fakes::HearingRepository.find_by_date(date)

      hearing
    end
  end
end
