# frozen_string_literal: true

# create queue correspondence seeds
require_relative "./helpers/queue_helpers"

module Seeds
  # :reek:InstanceVariableAssumption
  class QueueCorrespondences < Base
    include QueueHelpers

    def initialize
      initial_id_values
      RequestStore[:current_user] = User.find_by_css_id("JOLLY_POSTMAN")
    end

    def mail_team_user
      @mail_team_user ||= User.find_by_css_id("JOLLY_POSTMAN")
    end

    def seed!
      create_queue_correspondences
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

    # rubocop:disable Metrics/MethodLength
    def create_queue_correspondences
      # 20 Correspondences with eFolderFailedUploadTask with a parent CorrespondenceIntakeTask
      veteran = create_veteran(first_name: "John", last_name: "Doe")
      appeal = create_appeal(veteran)

      ptask = create_correspondence_intake(create_correspondence(appeal), status: "on_hold")

      # 20 Correspondences with eFolderFailedUploadTask with a parent CorrespondenceIntakeTask
      20.times do
        create_correspondence_with_intake_and_failed_upload_task
      end

      # 20 Correspondences with CorrespondenceIntakeTask with a status of in_progress
      20.times do
        create_correspondence_with_intake_task
      end

      # 20 Correspondences with eFolderFailedUploadTask with a parent ReviewPackageTask
      20.times do
        create_correspondence_with_review_package_and_failed_upload_task
      end

      # 20 Correspondences with the CorrespondenceRootTask with the status of completed
      20.times do
        create_correspondence_with_completed_root_task
      end

      # 20 Correspondences with ReviewPackageTask in progress
      20.times do
        create_correspondence_with_review_package_task
      end

      # 20 Correspondences with the tasks for Action Required tab and an on_hold ReviewPackageTask as their parent
      5.times do
        # below method creates 4 correspondence records
        create_correspondence_with_action_required_tasks
      end

      # 10 Correspondences with in-progress CorrespondenceRootTask and completed Mail Task
      10.times do
        create_correspondence_with_completed_mail_task
      end

      # 5 Correspondences with the CorrespondenceRootTask with the status of canceled
      5.times do
        create_correspondence_with_canceled_root_task
      end

      # 20 Correspondences with the tasks for CAVC and Congress Interest
      20.times do
        create_cavc_mailtask(create_correspondence, mail_team_user)
      end

      20.times do
        create_congress_interest_mailtask(create_correspondence, mail_team_user)
      end
    end
    # rubocop:enable Metrics/MethodLength

<<<<<<<<< Temporary merge branch 1
    def create_correspondence_with_intake_and_failed_upload_task(ptask, appeal)

      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = rand(1..10).days.ago
      corres.save

      create_efolderupload_failed_task(corres, ptask: ptask)

      corres
    end

    def create_correspondence_with_intake_task(appeal)
      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = 2.days.ago

      create_correspondence_intake(corres, status: "in_progress")

      corres
    end

    def create_correspondence_with_review_package_task(appeal)
      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = 3.days.ago
      create_review_package_task(corres, status: "in_progress")

      corres
    end

    def create_correspondence_with_review_package_and_failed_upload_task(appeal)
      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = 4.days.ago
      ptask = ReviewPackageTask.find_by(appeal_id: corres.id, type: ReviewPackageTask.name)
      create_efolderupload_failed_task(corres, ptask: ptask)
      ptask.update!(status: "on_hold")

      corres
    end

    def create_correspondence_with_completed_root_task(appeal)
      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = 5.days.ago
      create_correspondence_root_task(corres, status: "completed")

      corres
    end

    def create_correspondence_with_action_required_tasks(appeal)
      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = 6.days.ago
      review_package_task = ReviewPackageTask.find_by(appeal_id: corres.id, type: ReviewPackageTask.name)

      [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask].each do |task_type|
        check_and_create_action_required_task(corres, review_package_task, task_type)
      end

      review_package_task.update!(status: "on_hold")

      corres

=========
    def create_correspondence_with_intake_and_failed_upload_task(parent_task)
      corres = create_correspondence
      create_efolderupload_failed_task(corres, parent_task)
    end

    def create_correspondence_with_intake_task
      corres = create_correspondence
      create_correspondence_intake(corres, mail_team_user)
    end

    def create_correspondence_with_review_package_task
      corres = create_correspondence
      assign_review_package_task(corres, mail_team_user)
    end

    def create_correspondence_with_review_package_and_failed_upload_task
      corres = create_correspondence
      assign_review_package_task(corres, mail_team_user)
      parent_task = ReviewPackageTask.find_by(appeal_id: corres.id, type: ReviewPackageTask.name)
      create_efolderupload_failed_task(corres, parent_task)
    end

    def create_correspondence_with_completed_root_task
      corres = create_correspondence
      corres.root_task.update!(status: Constants.TASK_STATUSES.completed)
>>>>>>>>> Temporary merge branch 2
    end

    def create_correspondence_with_action_required_tasks
      corres_array = (1..4).map { create_correspondence }
      task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

      corres_array.each_with_index do |corres, index|
        rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
        task_array[index].create!(
          parent_id: rpt.id,
          appeal_id: corres.id,
          appeal_type: "Correspondence",
          assigned_to: MailTeamSupervisor.singleton
        )
      end
    end

<<<<<<<<< Temporary merge branch 1
    def create_correspondence_with_in_progress_root_task_and_completed_mail_task(appeal)
      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = 7.days.ago
      ptask = CorrespondenceRootTask.find_by(appeal_id: corres.id, type: CorrespondenceRootTask.name)
      create_in_progress_root_task_and_completed_mail_task(corres, parent_task: ptask, status: "completed")
      ptask.update!(status: "in_progress")

      corres
    end

    def create_correspondence_with_canceled_root_task(appeal)
      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = 8.days.ago
      create_correspondence_root_task(corres, status: "cancelled")

      corres
    end

    def create_pending_tasks(mail_task_parent, appeal)
      corres = create_correspondence(appeal)
      corres.va_date_of_receipt = 9.days.ago
      create_pending_tasks_for_tasks_not_related_to_appeal(corres, parent_task: mail_task_parent)

      corres
=========
    def create_correspondence_with_completed_mail_task
      correspondence = create_correspondence
      create_and_complete_mail_task(correspondence, mail_team_user)
    end

    def create_correspondence_with_canceled_root_task
      corres = create_correspondence
      corres.root_task.update!(status: Constants.TASK_STATUSES.cancelled)
>>>>>>>>> Temporary merge branch 2
    end
  end
end
