require "securerandom"

class Generators::Appeal
  extend Generators::Base

  class << self
    def default_attrs
      {
        vbms_id: generate_external_id,
        vacols_id: generate_external_id
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
      vacols_record = (attrs.delete(:vacols_record) || default_vacols_record).clone
      documents = attrs.delete(:documents)
      appeal = Appeal.new(default_attrs.merge(attrs))

      vacols_record[:vbms_id] = appeal.vbms_id

      Fakes::AppealRepository.records ||= {}
      Fakes::AppealRepository.records[appeal.vacols_id] = vacols_record

      Fakes::AppealRepository.document_records ||= {}
      Fakes::AppealRepository.document_records[appeal.vbms_id] = documents
      appeal
    end
  end
end
