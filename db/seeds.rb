# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require "database_cleaner"

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
class SeedDB

  ### Hearings Setup ###

  ### End Hearings Setup ###

  def create_annotations
    Generators::Annotation.create(comment: "Hello World!", document_id: 1, x: 300, y: 400)
    Generators::Annotation.create(comment: "This is an example comment", document_id: 2)
  end

  def create_tags
    DocumentsTag.create(
      tag_id: Generators::Tag.create(text: "Service Connected").id,
      document_id: 1
    )
    DocumentsTag.create(
      tag_id: Generators::Tag.create(text: "Right Knee").id,
      document_id: 2
    )
  end

  def create_root_task(appeal)
    FactoryBot.create(:root_task, appeal: appeal)
  end

  def create_appeal_at_judge_assignment(judge: User.find_by_css_id("BVAAABSHIRE"), assigned_at: Time.zone.now)
    description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
    notes = "Pain disorder with 100\% evaluation per examination"

    FactoryBot.create(
      :appeal,
      :assigned_to_judge,
      number_of_claimants: 1,
      associated_judge: judge,
      active_task_assigned_at: assigned_at,
      veteran_file_number: Generators::Random.unique_ssn,
      docket_type: Constants.AMA_DOCKETS.direct_review,
      closest_regional_office: "RO17",
      request_issues: FactoryBot.create_list(
        :request_issue, 2, :rating, contested_issue_description: description, notes: notes
      )
    )
  end

  def create_task_at_judge_assignment(appeal, judge, assigned_at = Time.zone.yesterday)
    FactoryBot.create(:ama_judge_task,
                      assigned_to: judge,
                      assigned_at: assigned_at,
                      appeal: appeal,
                      parent: create_root_task(appeal))
  end

  def create_task_at_judge_review(appeal, judge, attorney)
    parent = FactoryBot.create(:ama_judge_decision_review_task,
                               :in_progress,
                               assigned_to: judge,
                               appeal: appeal,
                               parent: create_root_task(appeal))
    child = FactoryBot.create(
      :ama_attorney_task,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: appeal
    )
    child.update(status: :completed)
    FactoryBot.create(:attorney_case_review, task_id: child.id)
  end

  def create_task_at_colocated(appeal, judge, attorney, trait = ColocatedTask.actions_assigned_to_colocated.sample.to_sym)
    parent = FactoryBot.create(
      :ama_judge_decision_review_task,
      assigned_to: judge,
      appeal: appeal,
      parent: create_root_task(appeal)
    )

    atty_task = FactoryBot.create(
      :ama_attorney_task,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: appeal
    )

    org_task_args = { appeal: appeal,
                      parent: atty_task,
                      assigned_by: attorney }
    FactoryBot.create(:ama_colocated_task, trait, org_task_args)
  end

  def create_colocated_legacy_tasks(attorney)
    [
      { vacols_id: "2096907", trait: :schedule_hearing },
      { vacols_id: "2226048", trait: :translation },
      { vacols_id: "2249056", trait: ColocatedTask.actions_assigned_to_colocated.sample.to_sym },
      { vacols_id: "2306397", trait: ColocatedTask.actions_assigned_to_colocated.sample.to_sym },
      { vacols_id: "2657227", trait: ColocatedTask.actions_assigned_to_colocated.sample.to_sym }
    ].each do |attrs|
      org_task_args = { appeal: LegacyAppeal.find_by(vacols_id: attrs[:vacols_id]),
                        assigned_by: attorney }
      FactoryBot.create(:colocated_task, attrs[:trait], org_task_args)
    end
  end

  def create_task_at_attorney_review(appeal, judge, attorney)
    parent = FactoryBot.create(
      :ama_judge_decision_review_task,
      assigned_to: judge,
      appeal: appeal,
      parent: create_root_task(appeal)
    )

    FactoryBot.create(
      :ama_attorney_task,
      :in_progress,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent,
      appeal: appeal
    )
  end

  def create_tasks
    attorney = User.find_by(css_id: "BVASCASPER1")
    judge = User.find_by(css_id: "BVAAABSHIRE")

    # At Judge Assignment
    # evidence submission docket
    create_task_at_judge_assignment(@ama_appeals[0], judge, 35.days.ago)
    create_task_at_judge_assignment(@ama_appeals[1], judge)

    create_task_at_judge_review(@ama_appeals[2], judge, attorney)
    create_task_at_judge_review(@ama_appeals[3], judge, attorney)
    create_task_at_colocated(@ama_appeals[4], judge, attorney)
    create_task_at_colocated(FactoryBot.create(:appeal), judge, attorney, :translation)
    create_task_at_attorney_review(@ama_appeals[5], judge, attorney)
    create_task_at_attorney_review(@ama_appeals[6], judge, attorney)
    create_task_at_judge_assignment(@ama_appeals[7], judge)
    create_task_at_judge_review(@ama_appeals[8], judge, attorney)
    create_task_at_colocated(@ama_appeals[9], judge, attorney)

    9.times do
      create_appeal_at_judge_assignment(judge: judge, assigned_at: Time.zone.today)
    end

    create_colocated_legacy_tasks(attorney)

    5.times do
      FactoryBot.create(
        :ama_task,
        assigned_by: judge,
        assigned_to: Translation.singleton,
        parent: FactoryBot.create(:root_task)
      )
    end

    3.times do
      FactoryBot.create(
        :ama_judge_task,
        :in_progress,
        assigned_to: User.find_by(css_id: "BVAEBECKER"),
        appeal: FactoryBot.create(:appeal)
      )
    end

    FactoryBot.create_list(
      :appeal,
      8,
      :with_post_intake_tasks,
      docket_type: Constants.AMA_DOCKETS.direct_review
    )

    create_tasks_at_acting_judge
  end

  def create_tasks_at_acting_judge
    attorney = User.find_by(css_id: "BVASCASPER1")
    judge = User.find_by(css_id: "BVAAABSHIRE")

    acting_judge = FactoryBot.create(:user, css_id: "BVAACTING", station_id: 101, full_name: "Kris ActingVLJ_AVLJ Merle")
    FactoryBot.create(:staff, :attorney_judge_role, user: acting_judge)

    JudgeTeam.create_for_judge(acting_judge)
    JudgeTeam.for_judge(judge).add_user(acting_judge)

    create_appeal_at_judge_assignment(judge: acting_judge)
    create_task_at_attorney_review(FactoryBot.create(:appeal), judge, acting_judge)
    create_task_at_attorney_review(FactoryBot.create(:appeal), acting_judge, attorney)
    create_task_at_judge_review(FactoryBot.create(:appeal), judge, acting_judge)
    create_task_at_judge_review(FactoryBot.create(:appeal), acting_judge, attorney)

    # Create Acting Judge Legacy Appeals
    create_legacy_appeal_at_acting_judge
  end

  def create_legacy_appeal_at_acting_judge
    # Find the 2 VACOLS Cases for the Acting Judge (seeded from local/vacols/VACOLS::Case_dump.csv)
    # - Case 3662860 does not have a decision drafted for it yet, so it is assigned to the AVLJ as an attorney
    # - Case 3662859 has a valid decision document, so it is assigned to the AVLJ as a judge
    vacols_case_attorney = VACOLS::Case.find_by(bfkey: "3662860")
    vacols_case_judge = VACOLS::Case.find_by(bfkey: "3662859")

    # Initialize the attorney and judge case issue list
    attorney_case_issues = []
    judge_case_issues = []
    %w[5240 5241 5242 5243 5250].each do |lev2|
      # Assign every other case issue to attorney
      case_issues = lev2.to_i.even? ? attorney_case_issues : judge_case_issues

      # Create issue and push into the case issues list
      case_issues << FactoryBot.create(:case_issue, issprog: "02", isscode: "15", isslev1: "04", isslev2: lev2)
    end

    # Update the Case with the Issues
    vacols_case_attorney.update!(case_issues: attorney_case_issues)
    vacols_case_judge.update!(case_issues: judge_case_issues)

    # Create the Judge and Attorney Legacy Appeals
    [vacols_case_attorney, vacols_case_judge].each do |vacols_case|
      # Assign the Vacols Case to the new Legacy Appeal
      FactoryBot.create(:legacy_appeal, vacols_case: vacols_case)
    end
  end

  def create_board_grant_tasks
    nca = BusinessLine.find_by(name: "National Cemetery Administration")
    description = "Service connection for pain disorder is granted with an evaluation of 50\% effective May 1 2011"
    notes = "Pain disorder with 80\% evaluation per examination"

    3.times do |index|
      board_grant_task = FactoryBot.create(:board_grant_effectuation_task,
                                           status: "assigned",
                                           assigned_to: nca)

      request_issues = FactoryBot.create_list(:request_issue, 3,
                                              :nonrating,
                                              contested_issue_description: "#{index} #{description}",
                                              notes: "#{index} #{notes}",
                                              benefit_type: nca.url,
                                              decision_review: board_grant_task.appeal)

      request_issues.each do |request_issue|
        # create matching decision issue
        FactoryBot.create(
          :decision_issue,
          :nonrating,
          disposition: "allowed",
          decision_review: board_grant_task.appeal,
          request_issues: [request_issue],
          rating_promulgation_date: 2.months.ago,
          benefit_type: request_issue.benefit_type
        )
      end
    end
  end

  def create_veteran_record_request_tasks
    nca = BusinessLine.find_by(name: "National Cemetery Administration")

    3.times do |_index|
      FactoryBot.create(:veteran_record_request_task,
                        status: "assigned",
                        assigned_to: nca)
    end
  end

  def clean_db
    DatabaseCleaner.clean_with(:truncation)
    cm = CacheManager.new
    CacheManager::BUCKETS.keys.each { |bucket| cm.clear(bucket) }
    Fakes::EndProductStore.new.clear!
    Fakes::RatingStore.new.clear!
    Fakes::VeteranStore.new.clear!
  end

  def setup_dispatch
    CreateEstablishClaimTasksJob.perform_now
    Timecop.freeze(Date.yesterday) do
      # Tasks prepared on today's date will not be picked up
      Dispatch::Task.all.each(&:prepare!)
      # Appeal decisions (decision dates) for partial grants have to be within 3 days
      CSV.foreach(Rails.root.join("local/vacols", "cases.csv"), headers: true) do |row|
        row_hash = row.to_h
        if %w[amc_full_grants remands_ready_for_claims_establishment].include?(row_hash["vbms_key"])
          VACOLS::Case.where(bfkey: row_hash["vacols_id"]).first.update(bfddec: Time.zone.today)
        end
      end
    end
  rescue AASM::InvalidTransition
    Rails.logger.info("Taks prepare job skipped - tasks were already prepared...")
  end

  def create_previously_held_hearing_data
    user = User.find_by_css_id("BVAAABSHIRE")
    appeal = LegacyAppeal.find_or_create_by(vacols_id: "3617215", vbms_id: "994806951S")

    return if ([appeal.type] - ["Post Remand", "Original"]).empty? &&
              appeal.hearings.map(&:disposition).include?(:held)

    FactoryBot.create(:case_hearing, :disposition_held, user: user, folder_nr: appeal.vacols_id)
  end

  def create_legacy_issues_eligible_for_opt_in
    # this vet number exists in local/vacols VBMS and BGS setup csv files.
    veteran_file_number_legacy_opt_in = "872958715S"
    legacy_vacols_id = "LEGACYID"

    # always delete and start fresh
    VACOLS::Case.where(bfkey: legacy_vacols_id).delete_all
    VACOLS::CaseIssue.where(isskey: legacy_vacols_id).delete_all

    case_issues = []
    %w[5240 5241 5242 5243 5250].each do |lev2|
      case_issues << FactoryBot.create(:case_issue,
                                       issprog: "02",
                                       isscode: "15",
                                       isslev1: "04",
                                       isslev2: lev2)
    end
    correspondent = VACOLS::Correspondent.find_or_create_by(stafkey: 100)
    folder = VACOLS::Folder.find_or_create_by(ticknum: legacy_vacols_id, tinum: 1)
    vacols_case = FactoryBot.create(:case_with_soc,
                                    :status_advance,
                                    case_issues: case_issues,
                                    correspondent: correspondent,
                                    folder: folder,
                                    bfkey: legacy_vacols_id,
                                    bfcorlid: veteran_file_number_legacy_opt_in)
    FactoryBot.create(:legacy_appeal, vacols_case: vacols_case)
  end

  def perform_seeding_jobs
    # Active Jobs which populate tables based on seed data
    UpdateCachedAppealsAttributesJob.perform_now
    NightlySyncsJob.perform_now
  end

  def call_and_log_seed_step(step)
    Rails.logger.debug("Starting seed step #{step}")
    send(step)
    Rails.logger.debug("Finished seed step #{step}")
  end

  def seed
    call_and_log_seed_step :clean_db

    # Annotations and tags don't come from VACOLS, so our seeding should
    # create them in all envs
    call_and_log_seed_step :create_annotations
    call_and_log_seed_step :create_tags

    call_and_log_seed_step :create_users
    call_and_log_seed_step :create_ama_appeals
    call_and_log_seed_step :create_hearing_days
    call_and_log_seed_step :create_tasks
    call_and_log_seed_step :create_higher_level_review_tasks
    call_and_log_seed_step :setup_dispatch
    call_and_log_seed_step :create_previously_held_hearing_data
    call_and_log_seed_step :create_legacy_issues_eligible_for_opt_in
    call_and_log_seed_step :create_higher_level_reviews_and_supplemental_claims
    call_and_log_seed_step :create_ama_hearing_appeals
    call_and_log_seed_step :create_board_grant_tasks
    call_and_log_seed_step :create_veteran_record_request_tasks
    call_and_log_seed_step :create_intake_users
    call_and_log_seed_step :create_inbox_messages
    call_and_log_seed_step :perform_seeding_jobs
    call_and_log_seed_step :setup_motion_to_vacate
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/ClassLength

SeedDB.new.seed
