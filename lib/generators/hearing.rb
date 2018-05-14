class Generators::Hearing
  extend Generators::Base

  class << self
    def default_attrs
      vacols_id = generate_external_id
      {
        type: :video,
        date: Time.zone.now - 5.days,
        venue_key: "RO13",
        vacols_id: vacols_id,
        vacols_record: { vacols_id: vacols_id },
        representative: "Military Order of the Purple Heart",
        representative_name: "#{generate_first_name} #{generate_last_name}",
        regional_office_key: RegionalOffice::CITIES.keys.sample,
        veteran_first_name: generate_first_name,
        veteran_middle_initial: "A",
        veteran_last_name: generate_last_name,
        appellant_first_name: generate_first_name,
        appellant_middle_initial: "A",
        appellant_last_name: generate_last_name,
        master_record: false
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

    def create(attrs = {})
      attrs = default_attrs.merge(attrs)
      hearing = ::Hearing.find_or_create_by(vacols_id: attrs[:vacols_id])
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || default_appeal_id(hearing)
      attrs[:appeal_vacols_id] = LegacyAppeal.find(attrs[:appeal_id]).vacols_id
      attrs[:user_id] ||= attrs[:user].try(:id) || Generators::User.create.id
      hearing.update_attributes(attrs)

      Fakes::HearingRepository.hearing_records ||= []

      if Fakes::HearingRepository.find_by_id(hearing.id)
        # If the hearing was already in our in-memory hearing_records store, replace it.
        i = Fakes::HearingRepository.find_index_by_id(hearing.id)
        Fakes::HearingRepository.hearing_records[i] = hearing
      else
        Fakes::HearingRepository.hearing_records.push(hearing)
      end

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
