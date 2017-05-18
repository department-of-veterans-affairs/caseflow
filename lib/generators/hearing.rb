class Generators::Hearing
  extend Generators::Base

  class << self
    def default_attrs
      {
        type: :video,
        date: Time.zone.now - 5.days,
        venue_key: "RO13",
        vacols_id: generate_external_id
      }
    end

    def build(attrs = {})
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || Generators::Appeal.create.id
      attrs[:user_id] ||= attrs[:user].try(:id) || Generators::User.create.id
      hearing = ::Hearing.new(default_attrs.merge(attrs))

      Fakes::AppealRepository.hearing_records ||= []
      Fakes::AppealRepository.hearing_records.push(hearing)

      hearing
    end
  end
end
