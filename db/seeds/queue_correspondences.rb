# frozen_string_literal: true

# create queue correspondence seeds
require_relative "./helpers/queue_helpers"

module Seeds
  # :reek:InstanceVariableAssumption
  class QueueCorrespondences < Base
    include QueueHelpers

    def initialize
      initial_id_values
      if RequestStore[:current_user].blank?
        RequestStore[:current_user] = User.find_by_css_id("INBOUND_OPS_TEAM_MAIL_INTAKE_USER")
      end
    end

    def inbound_ops_team_user
      @inbound_ops_team_user ||= User.find_by_css_id("INBOUND_OPS_TEAM_MAIL_INTAKE_USER")
    end

    def mail_team_superuser
      @mail_team_superuser ||= User.find_by_css_id("AMBRISVACO")
    end

    # seed with values for UAT rake task correspondence.rake
    # seed without values for Demo (default)
    def seed!(user = {}, veteran = {})

      return create_queue_correspondences(user, veteran) unless user.blank? && veteran.blank?

      create_queue_correspondences(inbound_ops_team_user)
      create_queue_correspondences(mail_team_superuser)
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
    def create_queue_correspondences(user, veteran = {})
      # 15 Correspondences with unassigned ReviewPackageTask
      15.times do
        create_correspondence_with_unassigned_review_package_task(user, veteran)
      end

      # 15 Correspondences with eFolderFailedUploadTask with a parent CorrespondenceIntakeTask
      15.times do
        create_correspondence_with_intake_and_failed_upload_task(user, veteran)
      end

      # 15 Correspondences with CorrespondenceIntakeTask with a status of in_progress
      15.times do
        create_correspondence_with_intake_task(user, veteran)
      end

      # 15 Correspondences with eFolderFailedUploadTask with a parent ReviewPackageTask
      15.times do
        create_correspondence_with_review_package_and_failed_upload_task(user, veteran)
      end

      # 15 Correspondences with the CorrespondenceRootTask with the status of completed
      15.times do
        create_correspondence_with_completed_root_task(user, veteran)
      end

      # 15 Correspondences with ReviewPackageTask in progress
      15.times do
        create_correspondence_with_review_package_task(user, veteran)
      end

      # 15 Correspondences with the tasks for Action Required tab and an on_hold ReviewPackageTask as their parent
      5.times do
        # below method creates 4 correspondence records
        create_correspondence_with_action_required_tasks(user, veteran)
      end

      # 20 correspondences with reassign / remove task for action required
      20.times do
        create_correspondences_with_review_remove_package_tasks
      end

      # 15 Correspondences with in-progress CorrespondenceRootTask and completed Mail Task
      15.times do
        create_correspondence_with_completed_mail_task(user, veteran)
      end
      # 15 Correspondences with in-progress CorrespondenceRootTask and completed Mail Task
      15.times do
        create_correspondence_with_completed_mail_task(user, veteran)
      end

      # 5 Correspondences with the CorrespondenceRootTask with the status of canceled
      5.times do
        create_correspondence_with_canceled_root_task(user, veteran)
      end

      # 15 Correspondences with the tasks for CAVC and Congress Interest
      15.times do
        create_cavc_mailtask(create_correspondence, user)
      end

      15.times do
        create_congress_interest_mailtask(create_correspondence, user)
      end

      15.times do
        create_correspondence_with_in_progress_review_package_task(user, veteran)
      end

      15.times do
        create_correspondence_with_in_progress_intake_task(user, veteran)
      end
    end
    # rubocop:enable Metrics/MethodLength

    def create_correspondence_with_intake_and_failed_upload_task(user, veteran = {})
      corres = create_correspondence(user,veteran)
      parent_task = create_correspondence_intake(corres, user)
      create_efolderupload_failed_task(corres, parent_task)
    end

    def create_correspondence_with_intake_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      create_correspondence_intake(corres, user)
    end

    def create_correspondence_with_in_progress_intake_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      cit = create_correspondence_intake(corres, user)
      cit.update!(status: Constants.TASK_STATUSES.in_progress)
    end

    def create_correspondence_with_unassigned_review_package_task(user = {}, veteran = {})
      corres = create_correspondence(user, veteran)
      # vary days waiting to be able to test column sorting
      rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
      rpt.update(assigned_at: corres.va_date_of_receipt)
    end

    def create_correspondence_with_review_package_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      assign_review_package_task(corres, user)
    end

    def create_correspondence_with_in_progress_review_package_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      assign_review_package_task(corres, user)
      rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
      rpt.update!(status: Constants.TASK_STATUSES.in_progress)
    end

    def create_correspondence_with_review_package_and_failed_upload_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      assign_review_package_task(corres, user)
      parent_task = ReviewPackageTask.find_by(appeal_id: corres.id, type: ReviewPackageTask.name)
      create_efolderupload_failed_task(corres, parent_task)
    end

    def create_correspondence_with_completed_root_task(user = {}, veteran = {})
      corres = create_correspondence(user, veteran)
      assign_review_package_task(corres, user)
      rpt = ReviewPackageTask.find_by(appeal_id: corres.id, type: ReviewPackageTask.name)
      rpt.update!(status: Constants.TASK_STATUSES.completed)
      corres.root_task.update!(status: Constants.TASK_STATUSES.completed)
      corres.root_task.update!(closed_at: rand(1.month.ago..1.day.ago))
    end

    def create_correspondence_with_action_required_tasks(user = {}, veteran = {})
      corres_array = (1..4).map { create_correspondence(user, veteran) }
      task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

      corres_array.each_with_index do |corres, index|
        rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
        rpt.update(assigned_to_id: InboundOpsTeam.singleton.users.first.id) if index.even?
        pat = task_array[index].create!(
          parent_id: rpt.id,
          appeal_id: corres.id,
          appeal_type: "Correspondence",
          assigned_to: InboundOpsTeam.singleton,
          assigned_by_id: rpt.assigned_to_id,
          instructions: ["Test instructions for #{task_array[index]&.name}."]
        )
        pat.update(assigned_at: corres.va_date_of_receipt)
      end
    end

    def create_correspondences_with_review_remove_package_tasks
        corres_array = (1..2).map { create(:correspondence) }
        task_array = [ReassignPackageTask, RemovePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_type: "Correspondence",
            appeal_id: corres.id,
            assigned_to: InboundOpsTeam.singleton,
            assigned_by_id: rpt.assigned_to_id,
            instructions: ["Test instructions for #{task_array[index]&.name}."]
          )
        end
    end

    def create_correspondence_with_completed_mail_task(user, veteran = {})
      correspondence = create_correspondence(user, veteran)
      create_and_complete_mail_task(correspondence, user)
    end

    def create_correspondence_with_canceled_root_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      corres.root_task.update!(status: Constants.TASK_STATUSES.cancelled)
    end
end
end
