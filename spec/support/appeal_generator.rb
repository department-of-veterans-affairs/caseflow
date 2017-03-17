require "securerandom"

class AppealGenerator
  class << self
    def generate_id
      SecureRandom.hex[0..6]
    end

    def default_attrs
      {
        vbms_id: generate_id,
        vacols_id: generate_id
      }
    end

    def default_vacols_record
      {
        veteran_first_name: "Davy",
        veteran_last_name: "Crockett",
        decision_date: 7.days.ago
      }
    end

    def build(attrs = {})
      vacols_record = attrs.delete(:vacols_record) || default_vacols_record
      documents = attrs.delete(:documents)
      appeal = Appeal.new(default_attrs.merge(attrs))

      Fakes::AppealRepository.records ||= {}
      Fakes::AppealRepository.records[appeal.vacols_id] = vacols_record

      Fakes::AppealRepository.document_records ||= {}
      Fakes::AppealRepository.document_records[appeal.vbms_id] = documents
      appeal
    end

    def create(attrs = {})
      AppealGenerator.build(attrs).tap(&:save!)
    end
  end
end
