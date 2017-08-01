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
        worksheet_witness: "Jane Doe attended",
        worksheet_contentions: "The veteran believes their knee is hurt",
        worksheet_evidence: "Medical exam occurred on 10/10/2008",
        worksheet_comments_for_attorney: "Look for knee-related medical records"
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
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || default_appeal.id unless hearing.appeal_id
      attrs[:user_id] ||= attrs[:user].try(:id) || Generators::User.create.id unless hearing.user_id
      hearing.update_attributes(attrs)

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
