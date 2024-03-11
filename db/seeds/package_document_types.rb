# frozen_string_literal: true

module Seeds
  class PackageDocumentTypes
    def seed!
      perform_seeding_correspondence_types
    end

    private

    def perform_seeding_correspondence_types
      # Active Jobs which populate tables based on seed data
      [
        "0304", "0779", "0781", "0781a", "0820a", "0820b", "0820c", "0820e", "0820f", "082d", "0966", "0995", "0996",
        "10007", "10182", "1330", "1330m", "1900", "1905", "1905c", "1905m", "1995", "1999", "1999b", "21-22",
        "21-22a", "247", "2680", "296", "4138", "4142", "4706b", "4706c", "4718a", "516", "518", "526", "526b",
        "526c", "526ez", "527", "527EZ", "530", "530a", "535", "537", "5490", "5495", "601", "674", "674c",
        "8049", "820", "8416", "8940", "BENE TRVL", "CH 31 APP", "CH36 APP", "CONG INQ", "CONSNT",
        "DBQ", "Debt Dispute", "GRADES/DEGREE", "IU", "NOD", "OMPF", "PMR", "RAMP", "REHAB PLAN", "RFA", "RM",
        "RNI", "SF180", "STR", "VA 9", "VCAA", "VRE INV"
      ].each do |package_document_type|
        PackageDocumentType.find_or_create_by(name: package_document_type)
      end
    end
  end
end
