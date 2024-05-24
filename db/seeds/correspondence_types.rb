# frozen_string_literal: true

# Create correspondence type seeds

module Seeds
  class CorrespondenceTypes < Base
    def seed!
      create_correspondence_types
    end

    private

    def create_correspondence_types
      correspondence_types_list =
        ["Abeyance",
         "Attorney Inquiry",
         "CAVC Correspondence",
         "Change of address",
         "Congressional interest",
         "CUE related",
         "Death certificate",
         "Evidence or argument",
         "Extension request",
         "FOIA request",
         "Hearing Postponement Request",
         "Hearing related",
         "Hearing Withdrawal Request",
         "Advance on docket",
         "Motion for reconsideration",
         "Motion to vacate",
         "Other motions",
         "Power of attorney related",
         "Privacy Act complaints",
         "Privacy Act request",
         "Returned as undeliverable mail",
         "Status Inquiry",
         "Thurber",
         "Withdrawal of appeal"]

      correspondence_types_list.each do |type|
        CorrespondenceType.find_or_create_by(name: type)
      end
    end
  end
end
