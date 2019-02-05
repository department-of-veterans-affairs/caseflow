class Generators::Hearing
  extend Generators::Base

  class << self
    def default_attrs
      {
        request_type: "V",
        scheduled_for: Time.zone.now - 5.days,
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

      t.integer "appeal_id", null: false
      t.string "bva_poc"
      t.string "disposition"
      t.boolean "evidence_window_waived"
      t.integer "hearing_day_id", null: false
      t.integer "judge_id"
      t.string "military_service"
      t.string "notes"
      t.boolean "prepped"
      t.string "representative_name"
      t.string "room"
      t.time "scheduled_time", null: false
      t.text "summary"
      t.boolean "transcript_requested"
      t.date "transcript_sent_date"
      t.uuid "uuid", default: -> { "uuid_generate_v4()" }, null: false
      t.string "witness"
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
      veteran_id = generate_external_id
      Appeal.create(veteran: Generators::Veteran.build(file_number: veteran_id))
    end

    def documents
      Fakes::Data::AppealData.reader_docs_no_categories
    end

    def default_appeal_id(hearing)
      if hearing.appeal_id
        Generators::Appeal.build(
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
