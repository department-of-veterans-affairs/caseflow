# frozen_string_literal: true

module Seeds
  class CorrespondenceSeed < Base
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

    def inbound_ops_team_superuser
      @inbound_ops_team_superuser ||= User.find_by_css_id("INBOUND_OPS_TEAM_SUPERUSER1")
    end

    def seed!
      create_correspondence_types
      perform_seeding_correspondence_types
      create_auto_text_data
      create_queue_correspondences(inbound_ops_team_user)
      create_queue_correspondences(inbound_ops_team_superuser)
      create_auto_assign_levers
    end

    def create_auto_text_data
      correspondence_auto_texts.each do |text|
        AutoText.find_or_create_by(name: text)
      end
    end

    def create_auto_assign_levers
      correspondence_auto_assignment_levers.each do |lever|
        CorrespondenceAutoAssignmentLever.find_or_create_by(name: lever[:name]) do |l|
          l.description = lever[:description]
          l.value = lever[:value]
          l.enabled = lever[:enabled]
        end
      end
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



    def create_correspondence_types
      correspondence_types_list =
        ["Abeyance",
         "Attorney Inquiry",
         "CAVC Correspondence",
         "Change of address",
         "Congressional interest",
         "CUE related",
         "Death certificate",
         "Evidence or argument",
         "Extension request",
         "FOIA request",
         "Hearing Postponement Request",
         "Hearing related",
         "Hearing Withdrawal Request",
         "Advance on docket",
         "Motion for reconsideration",
         "Motion to vacate",
         "Other motions",
         "Power of attorney related",
         "Privacy Act complaints",
         "Privacy Act request",
         "Returned as undeliverable mail",
         "Status Inquiry",
         "Thurber",
         "Withdrawal of appeal"]

      correspondence_types_list.each do |type|
        CorrespondenceType.find_or_create_by(name: type)
      end
    end

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

    def correspondence_auto_texts
      [
        "Address updated in VACOLS",
        "Decision sent to Senator or Congressman mm/dd/yy",
        "Interest noted in telephone call of mm/dd/yy",
        "Interest noted in evidence file regarding current appeal",
        "Email - responded via email on mm/dd/yy",
        "Email - written response req; confirmed receipt via email to Congress office on mm/dd/yy",
        "Possible motion pursuant to BVA decision dated mm/dd/yy",
        "Motion pursuant to BVA decision dated mm/dd/yy",
        "Statement in support of appeal by appellant",
        "Statement in support of appeal by rep",
        "Medical evidence X-Rays submitted or referred by",
        "Medical evidence clinical reports submitted or referred by",
        "Medical evidence examination reports submitted or referred by",
        "Medical evidence progress notes submitted or referred by",
        "Medical evidence physician's medical statement submitted or referred by",
        "C&P exam report",
        "Consent form (specify)",
        "Withdrawal of issues",
        "Response to BVA solicitation letter dated mm/dd/yy",
        "VAF 9 (specify)"
      ]
    end

    def create_veterans
      veterans = []
      15.times do |i|
        # Create the veteran
        @file_number += 1
        @participant_id += 1
        veteran = create(:veteran, file_number: @file_number, participant_id: @participant_id)
        10.times do
          appeal = create(:appeal, veteran: veteran)
          InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
        end
        veterans << veteran
      end
      veterans
    end

    def create_queue_correspondences(user)
      veterans = create_veterans
      veterans.each do |veteran|
        #Correspondences with unassigned ReviewPackageTask
        create_correspondence_with_unassigned_review_package_task(user, veteran)

        #Correspondences with eFolderFailedUploadTask with a parent CorrespondenceIntakeTask
        create_correspondence_with_intake_and_failed_upload_task(user, veteran)

        #Correspondences with CorrespondenceIntakeTask with a status of in_progress
        create_correspondence_with_intake_task(user, veteran)

        #Correspondences with eFolderFailedUploadTask with a parent ReviewPackageTask
        create_correspondence_with_review_package_and_failed_upload_task(user, veteran)

        #Correspondences with the CorrespondenceRootTask with the status of completed
        create_correspondence_with_completed_root_task(user, veteran)

        #Correspondences with ReviewPackageTask in progress
        create_correspondence_with_review_package_task(user, veteran)

        #Correspondences with the tasks for Action Required tab and an on_hold ReviewPackageTask as their parent
        create_correspondence_with_action_required_tasks(user, veteran)

        #correspondences with reassign / remove task for action required
        create_correspondences_with_review_remove_package_tasks

        #Correspondences with in-progress CorrespondenceRootTask and completed Mail Task
        create_correspondence_with_completed_mail_task(user, veteran)

        # Correspondences with the CorrespondenceRootTask with the status of canceled
        create_correspondence_with_canceled_root_task(user, veteran)

        #Correspondences with the tasks for CAVC and Congress Interest
        create_cavc_mailtask(user, veteran)

        create_congress_interest_mailtask(user, veteran)
        create_correspondence_with_in_progress_review_package_task(user, veteran)
        create_correspondence_with_in_progress_intake_task(user, veteran)
        create_nod_correspondence(user, veteran)
      end
    end

    def create_correspondence_with_unassigned_review_package_task(user = {}, veteran = {})
      corres = create_correspondence(user, veteran)
      create_correspondence_document(corres, veteran)
      # vary days waiting to be able to test column sorting
      rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
      rpt.update(assigned_at: corres.va_date_of_receipt)
    end

    def create_correspondence_with_intake_and_failed_upload_task(user, veteran = {})
      corres = create_correspondence(user,veteran)
      parent_task = create_correspondence_intake(corres, user)
      create_efolderupload_failed_task(corres, parent_task)
    end

    def create_correspondence_with_intake_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      create_correspondence_intake(corres, user)
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

    def create_correspondence_with_review_package_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      assign_review_package_task(corres, user)
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

    def create_cavc_mailtask(user, veteran = {})
      correspondence = create_correspondence(user, veteran)
      process_correspondence(correspondence, user)
      assigned_by = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id).completed_by
      task = CavcCorrespondenceCorrespondenceTask.create!(
        parent_id: correspondence&.root_task&.id,
        appeal_id: correspondence.id,
        appeal_type: "Correspondence",
        assigned_by: assigned_by,
        assigned_to: CavcLitigationSupport.singleton,
        status: Constants.TASK_STATUSES.assigned
      )
      randomize_days_waiting_value(task)
      task
    end

    def create_congress_interest_mailtask(user, veteran = {})
      correspondence = create_correspondence(user, veteran)
      process_correspondence(correspondence, user)
      assigned_by = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id).completed_by
      task = CongressionalInterestCorrespondenceTask.create!(
        appeal_id: correspondence.id,
        appeal_type: "Correspondence",
        assigned_by: assigned_by,
        assigned_to: LitigationSupport.singleton,
        status: Constants.TASK_STATUSES.assigned,
        parent_id: correspondence&.root_task&.id
      )
      randomize_days_waiting_value(task)
      task
    end

    def create_correspondence_with_in_progress_review_package_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      assign_review_package_task(corres, user)
      rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
      rpt.update!(status: Constants.TASK_STATUSES.in_progress)
    end

    def create_correspondence_with_in_progress_intake_task(user, veteran = {})
      corres = create_correspondence(user, veteran)
      cit = create_correspondence_intake(corres, user)
      cit.update!(status: Constants.TASK_STATUSES.in_progress)
    end

    def create_nod_correspondence(user, veteran = {})
      corres = create_correspondence(user, veteran)
      create_multiple_docs(corres, veteran)
    end

    def correspondence_auto_assignment_levers
      capacity_description = <<~EOS
        Any Mail Team User or Mail Superuser with equal to or more than this amount will be excluded from Auto-assign
      EOS

      return [
        {
          name: "capacity",
          description: capacity_description,
          value: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.max_assigned_tasks,
          enabled: true
        }
      ]
    end

  end
end
