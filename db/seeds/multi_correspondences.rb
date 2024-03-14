# frozen_string_literal: true

# create correspondence seeds
require_relative "./helpers/queue_helpers"

module Seeds
  # :reek:InstanceVariableAssumption
  class MultiCorrespondences < Base

    include QueueHelpers

    def initialize
      initial_id_values
      RequestStore[:current_user] = User.find_by_css_id("BVADWISE") if RequestStore[:current_user].blank?
    end

    # seed with values for UAT rake task correspondence.rake
    # seed without values for Demo (default)
    def seed!(user = {}, veteran = {})
      create_multi_correspondences(user, veteran)
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

    # creates correspondences for given vet (UAT)
    # default, creates Batman vets to assign cases to (demo)
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_multi_correspondences(user = {}, veteran = {})
      if user.blank?
        user = User.find_by_css_id("JOLLY_POSTMAN")
        # create veterans
        west = create_veteran(first_name: "Adam", last_name: "West")
        bale = create_veteran(first_name: "Christian", last_name: "Bale")
        keaton = create_veteran(first_name: "Michael", last_name: "Keaton")

        # build correspondences
        build_correspondences(west, user, 5)
        build_correspondences(bale, user, 10)
        build_correspondences(keaton, user, 20)
        return
      end

      # used for UAT correspondence.rake
      build_correspondences(veteran, user, 20)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def build_correspondences(veteran, user, iterations = 10)
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
      iterations.times do
        corres = ::Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: PackageDocumentType.all.sample.id,
          correspondence_type_id: CorrespondenceType.all.sample&.id,
          cmp_queue_id: 1,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: rand(1.month.ago..1.day.ago),
          notes: "Notes from CMP - Multi Correspondence Seed",
          assigned_by_id: user.id,
          updated_by_id: user.id,
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

        assign_review_package_task(corres, user)
      end
    end
  end
end
