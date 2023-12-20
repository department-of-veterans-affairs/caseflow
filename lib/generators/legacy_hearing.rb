# frozen_string_literal: true

class Generators::LegacyHearing
  extend Generators::Base

  class << self
    def default_attrs
      vacols_id = generate_external_id
      {
        request_type: HearingDay::REQUEST_TYPES[:video],
        scheduled_for: Time.zone.now - 5.days,
        venue_key: "RO13",
        vacols_id: vacols_id,
        vacols_record: { vacols_id: vacols_id },
        representative: "Military Order of the Purple Heart",
        representative_name: "#{generate_first_name} #{generate_last_name}",
        veteran_first_name: generate_first_name,
        veteran_middle_initial: "A",
        veteran_last_name: generate_last_name,
        appellant_first_name: generate_first_name,
        appellant_middle_initial: "A",
        appellant_last_name: generate_last_name
      }
    end

    def build(attrs = {})
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || default_appeal.id
      attrs[:user_id] ||= attrs[:user].try(:id) || Generators::User.create.id
      hearing = ::LegacyHearing.new(default_attrs.merge(attrs))

      hearing
    end

    def create(attrs = {})
      attrs = default_attrs.merge(attrs)
      hearing = ::LegacyHearing.find_or_create_by(vacols_id: attrs[:vacols_id])
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || default_appeal_id(hearing)
      attrs[:appeal_vacols_id] = LegacyAppeal.find(attrs[:appeal_id]).vacols_id
      attrs[:user_id] ||= attrs[:user].try(:id) || Generators::User.create.id
      hearing.update(attrs)

      hearing
    end

    private

    def default_appeal
      Generators::LegacyAppeal.create(vacols_record: { template: :pending_hearing }, documents: documents)
    end

    def documents
      Fakes::Data::AppealData.reader_docs_no_categories
    end

    def default_appeal_id(hearing)
      if hearing.appeal_id
        Generators::LegacyAppeal.build(
          vacols_record: { template: :pending_hearing },
          vacols_id: hearing.appeal.vacols_id,
          vbms_id: hearing.appeal.vbms_id,
          documents: documents
        )
        return hearing.appeal_id
      end
      default_appeal.id
    end
  end
end
