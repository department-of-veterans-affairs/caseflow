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
      # 20 Correspondences with eFolderFailedUploadTask with a parent CorrespondenceIntakeTask
      veteran = create_veteran(first_name: "John", last_name: "Doe")
      appeal = create_appeal(veteran)

      ptask = create_correspondence_intake(create_correspondence(appeal))

      # 20 Correspondences with eFolderFailedUploadTask with a parent CorrespondenceIntakeTask
      20.times do
        corres = create_correspondence_with_intake_and_failed_upload_task(ptask, appeal)
      end

      # 20 Correspondences with CorrespondenceIntakeTask with a status of in_progress
      20.times do
        corres = create_correspondence_with_intake_task(appeal)
      end

      review_package_parent_task = create_review_package_task(create_correspondence(appeal), status: "on_hold")
      # 20 Correspondences with eFolderFailedUploadTask with a parent ReviewPackageTask
      20.times do
        corres = create_correspondence_with_review_package_and_failed_upload_task(review_package_parent_task, appeal)
      end

      # 20 Correspondences with the CorrespondenceRootTask with the status of completed
      20.times do
        corres = create_correspondence_with_completed_root_task(appeal)
      end

      # 20 Correspondences with ReviewPackageTask in progress
      20.times do
        corres = create_correspondence_with_review_package_task(appeal)
      end

      action_required_parent_task = create_review_package_task(create_correspondence(appeal), status: "on_hold")
      # 20 Correspondences with the tasks for Action Required tab and an on_hold ReviewPackageTask as their parent
      20.times do
        corres = create_correspondence_with_action_required_tasks(action_required_parent_task, appeal)
      end

      parent_root_task =  create_correspondence_root_task(create_correspondence(appeal), status: "in_progress")
      # 10 Correspondences with in-progress CorrespondenceRootTask and completed Mail Task
      10.times do
        corres = create_correspondence_with_in_progress_root_task_and_completed_mail_task(appeal, parent_root_task)
      end

      # 5 Correspondences with the CorrespondenceRootTask with the status of canceled
      5.times do
        corres = create_correspondence_with_canceled_root_task(appeal)
      end
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

    def create_correspondence_with_review_package_task(appeal)
      corres = create_correspondence(appeal)

      create_review_package_task(corres, status: "in_progress")

      corres
    end

    def create_correspondence_with_review_package_and_failed_upload_task(review_package_parent_task, appeal)
      corres = create_correspondence(appeal)

      create_efolderupload_failed_task(corres, ptask: review_package_parent_task)

      corres
    end

    def create_correspondence_with_completed_root_task(appeal)
      corres = create_correspondence(appeal)

      create_correspondence_root_task(corres, status: "completed")

      corres
    end

    def create_correspondence_with_action_required_tasks(action_required_parent_task, appeal)
      corres = create_correspondence(appeal)

      create_action_required_tasks(corres, parent_task: action_required_parent_task, status: "assigned")

      corres
    end

    def create_correspondence_with_in_progress_root_task_and_completed_mail_task(appeal, parent_root_task)
      corres = create_correspondence(appeal)

      create_in_progress_root_task_and_completed_mail_task(corres, parent_task: parent_root_task, status: "completed")

      corres
    end

    def create_correspondence_with_canceled_root_task(appeal)
      corres = create_correspondence(appeal)

      create_correspondence_root_task(corres, status: "cancelled")

      corres
    end
  end
end
