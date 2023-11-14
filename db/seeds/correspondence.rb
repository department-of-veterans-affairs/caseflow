# frozen_string_literal: true

module Seeds
  # :reek:InstanceVariableAssumption
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

      @cmp_packet_number ||= 1_000_000_000
      @cmp_packet_number += 10_000 while ::Correspondence.find_by(cmp_packet_number: @cmp_packet_number + 1)
    end

    def create_veteran(options = {})
      @file_number += 1
      @participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      }
      veteran = create(:veteran, params.merge(options))
      5.times do
        create(:appeal, veteran_file_number: veteran.file_number)
      end
      veteran
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_correspondences
      10.times do
        veteran = create_veteran
        corres = ::Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: 15,
          correspondence_type_id: 8,
          cmp_queue_id: 1,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: Time.zone.yesterday,
          notes: "This is a note from CMP.",
          assigned_by_id: 81,
          veteran_id: veteran.id,
          prior_correspondence_id: 1
        )
        CorrespondenceDocument.create!(
          document_file_number: veteran.file_number,
          uuid: SecureRandom.uuid,
          vbms_document_id: "1250",
          correspondence: corres
        )
        @cmp_packet_number += 1
      end

      (1..77).each do |package_doc_id|
        veteran = create_veteran
        corres = ::Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: package_doc_id,
          correspondence_type_id: 8,
          cmp_queue_id: 1,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: Time.zone.yesterday,
          notes: "This is a note from CMP.",
          assigned_by_id: 81,
          veteran_id: veteran.id,
          prior_correspondence_id: 1
        )
        CorrespondenceDocument.create!(
          document_file_number: veteran.file_number,
          uuid: SecureRandom.uuid,
          vbms_document_id: "1250",
          correspondence: corres
        )
        @cmp_packet_number += 1
      end

      (1..24).each do |corres_type_id|
        veteran = create_veteran
        corres = ::Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: 15,
          correspondence_type_id: corres_type_id,
          cmp_queue_id: 1,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: Time.zone.yesterday,
          notes: "This is a note from CMP.",
          assigned_by_id: 81,
          veteran_id: veteran.id,
          prior_correspondence_id: 1
        )
        CorrespondenceDocument.create!(
          document_file_number: veteran.file_number,
          uuid: SecureRandom.uuid,
          vbms_document_id: "1250",
          correspondence: corres
        )
        @cmp_packet_number += 1
      end

      (1..17).each do |cmp_queue_id|
        veteran = create_veteran
        corres = ::Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: 15,
          correspondence_type_id: 8,
          cmp_queue_id: cmp_queue_id,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: Time.zone.yesterday,
          notes: "This is a note from CMP.",
          assigned_by_id: 81,
          veteran_id: veteran.id,
          prior_correspondence_id: 1
        )
        CorrespondenceDocument.create!(
          document_file_number: veteran.file_number,
          uuid: SecureRandom.uuid,
          vbms_document_id: "1250",
          correspondence: corres
        )
        @cmp_packet_number += 1
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    end
  end
end
