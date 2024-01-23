# frozen_string_literal: true

# create correspondence seeds
require_relative "./helpers/seed_helpers"

module Seeds
  # :reek:InstanceVariableAssumption
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

    def create_multi_correspondences
      # Create 20 Correspondences with eFolderFailedUploadTask with a parent CorrespondenceIntakeTask
      veteran = create_veteran(first_name: "John", last_name: "Doe")
      appeal = create_appeal(veteran)

      ptask = create_correspondence_intake(create_correspondence(appeal))

      20.times do
        corres = create_correspondence_with_intake_and_failed_upload_task(ptask, appeal)
      end

      # # Create 20 Correspondences with CorrespondenceIntakeTask with a status of in_progress
      # 20.times do
      #   corres = create_correspondence_with_intake_task
      # end
    end

    def create_correspondence_with_intake_and_failed_upload_task(ptask, appeal)

      corres = create_correspondence(appeal)

      create_efolderupload_failed_task(corres, ptask: ptask)

      corres
    end

    def create_correspondence_with_intake_task(appeal)
      corres = create_correspondence(appeal)

      create_correspondence_intake(corres)

      corres
    end
  end
end
