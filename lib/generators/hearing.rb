class Generators::Hearing
  extend Generators::Base

  class << self
    def default_attrs
      {
        type: :video,
        date: Time.now - 5.days,
        regional_office_key: "RO13",
        judge_vacols_id: "1039"
      }
    end

    def build(attrs = {})
      attrs[:vacols_case_id] ||= attrs[:appeal].try(:vacols_id) || Generators::Appeal.create.vacols_id
      ::Hearing.new(default_attrs.merge(attrs))
    end
  end
end
