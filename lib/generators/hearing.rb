class Generators::Hearing
  extend Generators::Base

  class << self
    def default_attrs
      {
        type: :video,
        date: Time.zone.now - 5.days,
        regional_office_key: "RO13"
      }
    end

    def build(attrs = {})
      attrs[:vacols_case_id] ||= attrs[:appeal].try(:vacols_id) || Generators::Appeal.create.vacols_id
      attrs[:vacols_user_id] ||= attrs[:user].try(:vacols_id) || Generators::User.create.vacols_id
      hearing = ::Hearing.new(default_attrs.merge(attrs))

      Fakes::AppealRepository.hearing_records ||= []
      Fakes::AppealRepository.hearing_records.push(hearing)

      hearing
    end
  end
end
