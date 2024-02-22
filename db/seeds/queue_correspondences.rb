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

    def mail_team_superuser
      @mail_team_superuser ||= User.find_by_css_id("AMBRISVACO")
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
      20.times do
        create_correspondence_with_intake_and_failed_upload_task(mail_team_user)
        create_correspondence_with_intake_and_failed_upload_task(mail_team_superuser)
      end

      # 20 Correspondences with CorrespondenceIntakeTask with a status of in_progress
      20.times do
        create_correspondence_with_intake_task(mail_team_user)
        create_correspondence_with_intake_task(mail_team_superuser)
      end

      # 20 Correspondences with eFolderFailedUploadTask with a parent ReviewPackageTask
      20.times do
        create_correspondence_with_review_package_and_failed_upload_task(mail_team_user)
        create_correspondence_with_review_package_and_failed_upload_task(mail_team_superuser)
      end

      # 20 Correspondences with the CorrespondenceRootTask with the status of completed
      20.times do
        create_correspondence_with_completed_root_task
      end

      # 20 Correspondences with ReviewPackageTask in progress
      20.times do
        create_correspondence_with_review_package_task(mail_team_user)
        create_correspondence_with_review_package_task(mail_team_superuser)
      end

      # 20 Correspondences with the tasks for Action Required tab and an on_hold ReviewPackageTask as their parent
      5.times do
        # below method creates 4 correspondence records
        create_correspondence_with_action_required_tasks
      end

      # 10 Correspondences with in-progress CorrespondenceRootTask and completed Mail Task
      10.times do
        create_correspondence_with_completed_mail_task(mail_team_user)
        create_correspondence_with_completed_mail_task(mail_team_superuser)
      end

      # 5 Correspondences with the CorrespondenceRootTask with the status of canceled
      5.times do
        create_correspondence_with_canceled_root_task
      end

      # 20 Correspondences with the tasks for CAVC and Congress Interest
      20.times do
        create_cavc_mailtask(create_correspondence, mail_team_user)
        create_cavc_mailtask(create_correspondence, mail_team_superuser)
      end

      20.times do
        create_congress_interest_mailtask(create_correspondence, mail_team_user)
        create_congress_interest_mailtask(create_correspondence, mail_team_superuser)
      end

      10.times do
        create_correspondence_with_in_progress_review_package_task(mail_team_user)
        create_correspondence_with_in_progress_review_package_task(mail_team_superuser)
      end

      10.times do
        create_correspondence_with_in_progress_intake_task(mail_team_user)
        create_correspondence_with_in_progress_intake_task(mail_team_superuser)
      end
    end
    # rubocop:enable Metrics/MethodLength

    def create_correspondence_with_intake_and_failed_upload_task(user)
      corres = create_correspondence
      parent_task = create_correspondence_intake(corres, user)
      create_efolderupload_failed_task(corres, parent_task)
    end

    def create_correspondence_with_intake_task(user)
      corres = create_correspondence
      create_correspondence_intake(corres, user)
    end

    def create_correspondence_with_in_progress_intake_task(user)
      corres = create_correspondence
      cit = create_correspondence_intake(corres, user)
      cit.update!(status: Constants.TASK_STATUSES.in_progress)
    end

    def create_correspondence_with_review_package_task(user)
      corres = create_correspondence
      assign_review_package_task(corres, user)
    end

    def create_correspondence_with_in_progress_review_package_task(user)
      corres = create_correspondence
      assign_review_package_task(corres, user)
      rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
      rpt.update!(status: Constants.TASK_STATUSES.in_progress)
    end

    def create_correspondence_with_review_package_and_failed_upload_task(user)
      corres = create_correspondence
      assign_review_package_task(corres, user)
      parent_task = ReviewPackageTask.find_by(appeal_id: corres.id, type: ReviewPackageTask.name)
      create_efolderupload_failed_task(corres, parent_task)
    end

    def create_correspondence_with_completed_root_task
      corres = create_correspondence
      corres.root_task.update!(status: Constants.TASK_STATUSES.completed)
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
          assigned_to: MailTeamSupervisor.singleton,
          assigned_by_id: rpt.assigned_to_id
        )
      end
    end

    def create_correspondence_with_completed_mail_task(user)
      correspondence = create_correspondence
      create_and_complete_mail_task(correspondence, user)
    end

    def create_correspondence_with_canceled_root_task
      corres = create_correspondence
      corres.root_task.update!(status: Constants.TASK_STATUSES.cancelled)
    end
  end
end
