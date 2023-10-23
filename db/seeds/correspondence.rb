# frozen_string_literal: true

module Seeds
  class Correspondence < Base
    def initialize
      initial_id_values
    end

    def seed!
      create_correspondences
    end

    private

    def initial_id_values
      @file_number ||= 500_000_000
      @participant_id ||= 850_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 100
        @participant_id += 100
      end
    end

    def create_veteran(options = {})
      @file_number += 1
      @participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def create_correspondences
      10.times do
        veteran = create_veteran

        corres = create(
          :correspondence,
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: 1250,
          cmp_packet_number: rand(1_000_000_000..9_999_999_999),
          va_date_of_receipt: Time.zone.yesterday,
          veteran_id: veteran.id
        )
        create(
          :correspondence_document,
          document_file_number: veteran.file_number,
          correspondence: corres
        )
      end
    end
  end
end
