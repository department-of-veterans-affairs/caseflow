class Generators::Contention
  extend Generators::Base

  class << self
    def default_attrs
      {
        id: generate_external_id,
        claim_id: generate_external_id,
        text: "Generic contention",
        start_date: 5.days.ago,
        submit_date: 5.days.ago
      }
    end

    def build(attrs = {})
      attrs = default_attrs.merge(attrs)
      claim_id = attrs.delete(:claim_id)

      OpenStruct.new(attrs).tap do |contention|
        Fakes::VBMSService.contention_records ||= {}
        Fakes::VBMSService.contention_records[claim_id] ||= []
        Fakes::VBMSService.contention_records[claim_id] << contention
      end
    end
  end
end
