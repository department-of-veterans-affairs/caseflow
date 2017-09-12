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
        witness: "Jane Doe attended",
        contentions: "The veteran believes their knee is hurt",
        evidence: "Medical exam occurred on 10/10/2008",
        military_service: "Veteran was in the Vietnam War",
        comments_for_attorney: "Look for knee-related medical records"
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
      attrs[:user_id] ||= attrs[:user].try(:id) || Generators::User.create.id
      hearing.update_attributes(attrs)
      hearing.set_issues_from_appeal

      Fakes::HearingRepository.hearing_records ||= []
      Fakes::HearingRepository.hearing_records.push(hearing) unless Fakes::HearingRepository.find_by_id(hearing.id)
      hearing
    end

    private

    def default_appeal
      Generators::Appeal.create(vacols_record: { template: :pending_hearing }, documents: documents)
    end

    def documents
      documents = []
      types = %w(NOD SOC SSOC)
      rand(5).times do
        documents << Generators::Document.build(type: types.sample, received_at: 4.days.ago)
      end
      documents
    end

    def default_appeal_id(hearing)
      if hearing.appeal_id
        Generators::Appeal.build(
          vacols_record: { template: :pending_hearing },
          vacols_id: hearing.appeal.vacols_id,
          documents: documents
        )
        return hearing.appeal_id
      end
      default_appeal.id
    end
  end
end
