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
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || default_appeal.id
      attrs[:user_id] ||= attrs[:user].try(:id) || Generators::User.create.id
      hearing = ::Hearing.new(default_attrs.merge(attrs))

      Fakes::HearingRepository.hearing_records ||= []
      Fakes::HearingRepository.hearing_records.push(hearing)

      hearing
    end

    private

    def default_appeal
      Generators::Appeal.create(vacols_record: { template: :pending_hearing })
    end

  end
end
