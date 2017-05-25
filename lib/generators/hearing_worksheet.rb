class Generators::HearingWorksheet
  extend Generators::Base

  class << self
    def default_attrs
      {
        witness: "Jane Doe attended",
        contentions: "The veteran believes their knee is hurt",
        evidence: "Medical exam occurred on 10/10/2008",
        comments_for_attorney: "Look for knee-related medical records",
        issues: []
      }
    end

    def build(attrs = {})
      attrs[:hearing_id] ||= attrs[:hearing].try(:id) || Generators::Hearing.create.id
      ::HearingWorksheet.new(default_attrs.merge(attrs))
    end
  end
end
