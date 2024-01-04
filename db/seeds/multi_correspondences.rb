# frozen_string_literal :true

# create correspondence seeds
# :reek:InstanceVariableAssumption
module Seeds
  class MultiCorrespondences < Base
    include SeedHelpers

    def initialize
      initial_id_values
      RequestStore[:current_user] = User.find_by_css_id("BVADWISE")
    end

    def seed!
      create_multi_correspondences
    end

    private

    def initial_id_values
      @file_number ||= 550_000_000
      @participant_id ||= 650_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 100
        @participant_id += 100
      end

      @cmp_packet_number ||= 2_000_000_000
      @cmp_packet_number += 10_000 while ::Correspondence.find_by(cmp_packet_number: @cmp_packet_number + 1)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_multi_correspondences
      veteran = create_veteran(first_name: "Adam", last_name: "West")
      5.times do
        appeal = create(
          :appeal,
          veteran_file_number: veteran.file_number
          )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
      5.times do
        appeal = create(
          :appeal,
          veteran_file_number: veteran.file_number,
          docket_type: Constants.AMA_DOCKETS.direct_review
          )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
      21.times do
        corres = ::Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: (1..20).to_a.sample,
          correspondence_type_id: 4,
          cmp_queue_id: 1,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: Time.zone.yesterday,
          notes: "Notes from CMP - Multi Correspondence Seed",
          assigned_by_id: 81,
          veteran_id: veteran.id,
        )
        CorrespondenceDocument.find_or_create_by(
          document_file_number: veteran.file_number,
          uuid: SecureRandom.uuid,
          vbms_document_type_id: 1250,
          document_type: 1250,
          pages: 30,
          correspondence_id: corres.id
        )
        @cmp_packet_number += 1
      end

      veteran = create_veteran(first_name: "Michael", last_name: "Keaton")
      2.times do
        appeal = create(
          :appeal,
          veteran_file_number: veteran.file_number
          )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
      5.times do
        appeal = create(
          :appeal,
          veteran_file_number: veteran.file_number,
          docket_type: Constants.AMA_DOCKETS.direct_review
          )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
      31.times do
        corres = ::Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: (1..20).to_a.sample,
          correspondence_type_id: 4,
          cmp_queue_id: 1,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: Time.zone.yesterday,
          notes: "Notes from CMP - Multi Correspondence Seed",
          assigned_by_id: 81,
          veteran_id: veteran.id,
        )
        CorrespondenceDocument.find_or_create_by(
          document_file_number: veteran.file_number,
          uuid: SecureRandom.uuid,
          vbms_document_type_id: 1250,
          document_type: 1250,
          pages: 30,
          correspondence_id: corres.id
        )
        @cmp_packet_number += 1
      end


      veteran = create_veteran(first_name: "Christian", last_name: "Bale")
      1.times do
        appeal = create(
          :appeal,
          veteran_file_number: veteran.file_number
          )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
      10.times do
        appeal = create(
          :appeal,
          veteran_file_number: veteran.file_number,
          docket_type: Constants.AMA_DOCKETS.direct_review
          )
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
      101.times do
        corres = ::Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: (1..20).to_a.sample,
          correspondence_type_id: 4,
          cmp_queue_id: 1,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: Time.zone.yesterday,
          notes: "Notes from CMP - Multi Correspondence Seed",
          assigned_by_id: 81,
          veteran_id: veteran.id,
        )
        CorrespondenceDocument.find_or_create_by(
          document_file_number: veteran.file_number,
          uuid: SecureRandom.uuid,
          vbms_document_type_id: 1250,
          document_type: 1250,
          pages: 30,
          correspondence_id: corres.id
        )
        @cmp_packet_number += 1
      end
    end
  end
end
