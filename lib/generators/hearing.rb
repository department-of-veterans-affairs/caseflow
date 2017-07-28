class Generators::Hearing
  extend Generators::Base

  class << self
    def default_attrs
      {
        type: :video,
        date: Time.zone.now - 5.days,
        venue_key: "RO13",
        vacols_id: generate_external_id,
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
      hearing = build(attrs)
      hearing.tap(&:save!) unless ::Hearing.exists?(vacols_id: attrs[:vacols_id])
      hearing
    end

    private

    def default_appeal
      Generators::Appeal.create(vacols_record: { template: :pending_hearing })
    end
  end
end
