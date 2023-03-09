# frozen_string_literal: true

namespace :letter_tasks do
  desc "create 10 appeals with post initial letter tasks that will expire in 2 days"
  task :create_post_task_appeals => :environment do
    # only allow to run in demo or test environment
    if Rails.env.development? || Rails.env.demo?
      cob = Organization.find_by_url("clerk-of-the-board")
      cob_user = User.find_by_css_id("COB_USER")
      RequestStore[:current_user] = cob_user

      # travel backwards to 44 days
      Timecop.travel(Time.zone.now - 44.days)

      # create appeals with root, distribution, and evidence submission tasks
      factory_appeals = 10.times.map do
        FactoryBot.create(
          :appeal,
          :ready_for_distribution,
          docket_type: Constants.AMA_DOCKETS.evidence_submission
        )
      end

      # create initial letter task for each appeal
      factory_appeals.each do |a|
        SendInitialNotificationLetterTask.create!(
          appeal: a,
          parent: a.tasks.find_by(type: "EvidenceSubmissionWindowTask"),
          assigned_to: cob,
          assigned_by: cob_user
        )
      end

      # create post letter for each appeal
      factory_appeals.each do |a|
        task = a.tasks.find_by(type: "SendInitialNotificationLetterTask")
        psi = PostSendInitialNotificationLetterHoldingTask.create!(
          appeal: a,
          parent: task.parent,
          assigned_to: cob,
          assigned_by: cob_user,
          end_date: Time.zone.now + 45.days
        )
        task.completed!
        TimedHoldTask.create_from_parent(psi, days_on_hold: 45, instructions: "instructions")
      end
      # return timecop to normal
      Timecop.return
    else
      STDOUT.puts("This script can only run in development(local) and demo; it cannot run in this environment")
    end

  end

  desc "create 10 appeals with final letter tasks for demo testing."
  task :create_final_letter_task_appeals => :environment do
    # only allow to run in demo or test environment
    if Rails.env.development? || Rails.env.demo?
      cob = Organization.find_by_url("clerk-of-the-board")
      cob_user = User.find_by_css_id("COB_USER")
      RequestStore[:current_user] = cob_user

      # create appeals with root, distribution, and evidence submission tasks
      factory_appeals = 10.times.map do
        FactoryBot.create(
          :appeal,
          :ready_for_distribution,
          docket_type: Constants.AMA_DOCKETS.evidence_submission
        )
      end

      # create initial and final letter task for each appeal
      factory_appeals.each do |a|
        sit = SendInitialNotificationLetterTask.create!(
          appeal: a,
          parent: a.tasks.find_by(type: "EvidenceSubmissionWindowTask"),
          assigned_to: cob,
          assigned_by: cob_user
        )
        sit.completed!
        SendFinalNotificationLetterTask.create!(
          appeal: a,
          parent: a.tasks.find_by(type: "EvidenceSubmissionWindowTask"),
          assigned_to: cob,
          assigned_by: cob_user
        )
      end
    else
      STDOUT.puts("This script can only run in development(local) and demo; it cannot run in this environment")
    end
  end
end
