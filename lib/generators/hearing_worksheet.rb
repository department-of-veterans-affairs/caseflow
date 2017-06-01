class Generators::HearingWorksheet
  extend Generators::Base

  class << self
    def default_attrs
      {
        worksheet_witness: "Jane Doe attended",
        worksheet_contentions: "The veteran believes their knee is hurt",
        worksheet_evidence: "Medical exam occurred on 10/10/2008",
        worksheet_comments_for_attorney: "Look for knee-related medical records"
      }
    end

    def build(attrs = {})
      # Build a hearing using the base attrs required, then merge
      # in worksheet-specific attributes
      hearing = Generators::Hearing.build

      # Use default Hearing attributes and "cast" the object to a HearingWorksheet
      hearing_worksheet = ::HearingWorksheet.new(hearing.attributes.merge(default_attrs)
                                                                   .merge(attrs))

      hearing_worksheet
    end
  end
end
