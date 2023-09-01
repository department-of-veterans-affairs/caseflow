# frozen_string_literal: true

# to create legacy appeals with AMA Tasks added, run "bundle exec rake db:generate_legacy_appeals_with_tasks"
# then select an option between 'HearingTask', 'JudgeTask', 'AttorneyTask', 'ReviewTask', 'Scenario1edge'
# and 'Brieff_Curloc_81_Task'

namespace :db do
  desc "Generates a smattering of legacy appeals with VACOLS cases that have special issues assocaited with them"
  task generate_legacy_appeals_with_tasks: :environment do
    class LegacyAppealFactory
      class << self
        def stamp_out_legacy_appeals(num_appeals_to_create, file_number, user, docket_number, task_type)
          # Changes location of vacols based on if you want a hearing task or only a legacy task in location 81
          bfcurloc = if task_type == "HEARINGTASK" || task_type == "SCENARIO1EDGE"
                       57
                     elsif task_type == "BRIEFF_CURLOC_81_TASK"
                       81
                     else
                       VACOLS::Staff.find_by(sdomainid: user.css_id).slogid
                     end

          veteran = Veteran.find_by_file_number(file_number)
          decass_scenarios = task_type == "HEARINGTASK" || task_type == "SCENARIO1EDGE" || task_type == "BRIEFF_CURLOC_81_TASK"
          fail ActiveRecord::RecordNotFound unless veteran

          vacols_veteran_record = find_or_create_vacols_veteran(veteran)

          # Creates decass for scenario1/2/4 tasks as they require an assigned_by field
          # which is grabbed from the Decass table (b/c it is an AttorneyLegacyTask)
          decass_creation = if decass_scenarios || (task_type == "ATTORNEYTASK" && user&.attorney_in_vacols?)
                              true
                            else false
                            end
          cases = Array.new(num_appeals_to_create).each_with_index.map do
            key = VACOLS::Folder.maximum(:ticknum).next

            staff = VACOLS::Staff.find_by(sdomainid: user.css_id) # user for local/demo || UAT
            Generators::Vacols::Case.create(
              decass_creation: decass_creation,
              corres_exists: true,
              folder_attrs: Generators::Vacols::Folder.folder_attrs.merge(
                custom_folder_attributes(vacols_veteran_record, docket_number.to_s)
              ),
              case_attrs: {
                bfcorkey: vacols_veteran_record.stafkey,
                bfcorlid: vacols_veteran_record.slogid,
                bfkey: key,
                bfcurloc: bfcurloc,
                bfmpro: "ACT",
                bfddec: nil
              },
              # Clean this up
              staff_attrs: custom_staff_attributes(staff),
              decass_attrs: custom_decass_attributes(key, user, decass_creation)
            )
          end.compact

          build_the_cases_in_caseflow(cases, task_type, user)
          # rubocop:enable, Metrics/ParameterLists, Metrics/MethodLength, Metrics/AbcSize, Layout/LineLength
        end

        def custom_folder_attributes(veteran, docket_number)
          {
            titrnum: veteran.slogid,
            tiocuser: nil,
            tinum: docket_number
          }
        end

        def custom_staff_attributes(staff)
          if staff
            {
              stafkey: staff.stafkey,
              susrpw: staff.susrpw || nil,
              susrsec: staff.susrsec || nil,
              susrtyp: staff.susrtyp || nil,
              ssalut: staff.ssalut || nil,
              snamef: staff.snamef,
              snamemi: staff.snamemi,
              snamel: staff.snamel,
              slogid: staff.slogid,
              stitle: staff.stitle,
              sorg: staff.sorg || nil,
              sdept: staff.sdept || nil,
              saddrnum: staff.saddrnum || nil,
              saddrst1: staff.saddrst1 || nil,
              saddrst2: staff.saddrst2 || nil,
              saddrcty: staff.saddrcty || nil,
              saddrstt: staff.saddrstt || nil,
              saddrcnty: staff.saddrcnty || nil,
              saddrzip: staff.saddrzip || nil,
              stelw: staff.stelw || nil,
              stelwex: staff.stelwex || nil,
              stelfax: staff.stelfax || nil,
              stelh: staff.stelh || nil,
              staduser: staff.staduser || nil,
              stadtime: staff.stadtime || nil,
              stmduser: staff.stmduser || nil,
              stmdtime: staff.stmdtime || nil,
              stc1: staff.stc1 || nil,
              stc2: staff.stc2 || nil,
              stc3: staff.stc3 || nil,
              stc4: staff.stc4 || nil,
              snotes: staff.snotes || nil,
              sorc1: staff.sorc1 || nil,
              sorc2: staff.sorc2 || nil,
              sorc3: staff.sorc3 || nil,
              sorc4: staff.sorc4 || nil,
              sactive: staff.sactive || nil,
              ssys: staff.ssys || nil,
              sspare1: staff.sspare1 || nil,
              sspare2: staff.sspare2 || nil,
              sspare3: staff.sspare3 || nil,
              smemgrp: staff.smemgrp || nil,
              sfoiasec: staff.sfoiasec || nil,
              srptsec: staff.srptsec || nil,
              sattyid: staff.sattyid || nil,
              svlj: staff.svlj || nil,
              sinvsec: staff.sinvsec || nil,
              sdomainid: staff.sdomainid || nil
            }
          end
        end

        def custom_decass_attributes(key, user, decass_creation)
          if decass_creation
            {
              defolder: key,
              deatty: user.id,
              deteam: "SBO",
              deassign: VacolsHelper.local_date_with_utc_timezone - 7.days,
              dereceive: VacolsHelper.local_date_with_utc_timezone,
              deadtim: VacolsHelper.local_date_with_utc_timezone - 7.days,
              demdtim: VacolsHelper.local_date_with_utc_timezone,
              decomp: VacolsHelper.local_date_with_utc_timezone,
              dedeadline: VacolsHelper.local_date_with_utc_timezone + 120.days
            }
          end
        end

        # Generators::Vacols::Case will create new correspondents, and I think it'll just be easier to
        # update the cases created rather than mess with the generator's internals.
        def find_or_create_vacols_veteran(veteran)
          # Being naughty and calling a private method (it'd be cool to have this be public...)
          vacols_veteran_record = VACOLS::Correspondent.send(:find_veteran_by_ssn, veteran.ssn).first

          return vacols_veteran_record if vacols_veteran_record

          Generators::Vacols::Correspondent.create(
            Generators::Vacols::Correspondent.correspondent_attrs.merge(
              ssalut: veteran.name_suffix,
              snamef: veteran.first_name,
              snamemi: veteran.middle_name,
              snamel: veteran.last_name,
              slogid: LegacyAppeal.convert_file_number_to_vacols(veteran.file_number)
            )
          )
        end

        ########################################################
        # Creates Hearing Tasks for the LegacyAppeals that have just been generated
        # Scenario 1
        def create_hearing_task_for_legacy_appeals(appeal)
          root_task = RootTask.find_or_create_by!(appeal: appeal)

          hearing_task = HearingTask.create!(
            appeal: appeal,
            parent: root_task,
            assigned_to: Bva.singleton
          )
          ScheduleHearingTask.create!(
            appeal: appeal,
            parent: hearing_task,
            assigned_to: Bva.singleton
          )
          $stdout.puts("You have created a Hearing Task")
        end

        ########################################################
        # Creates Attorney Tasks for the LegacyAppeals that have just been generated
        # Scenario 4
        def create_attorney_task_for_legacy_appeals(appeal, user)
          # Will need a judge user for judge decision review task and an attorney user for the subsequent Attorney Task
          root_task = RootTask.find_or_create_by!(appeal: appeal)

          review_task = JudgeDecisionReviewTask.create!(
            appeal: appeal,
            parent: root_task,
            assigned_to: User.find_by_css_id("BVAAABSHIRE")
          )
          AttorneyTask.create!(
            appeal: appeal,
            parent: review_task,
            assigned_to: user,
            assigned_by: User.find_by_css_id("BVAAABSHIRE")
          )
          $stdout.puts("You have created an Attorney task")
        end

        ########################################################
        # Creates Judge Assign Tasks for the LegacyAppeals that have just been generated
        # Scenario 3/5
        def create_judge_task_for_legacy_appeals(appeal, user)
          # User should be a judge
          root_task = RootTask.find_or_create_by!(appeal: appeal)

          JudgeAssignTask.create!(
            appeal: appeal,
            parent: root_task,
            assigned_to: user
          )
          $stdout.puts("You have created a Judge task")
        end

        ########################################################
        # Creates Review Tasks for the LegacyAppeals that have just been generated
        # Scenario 6/7
        def create_review_task_for_legacy_appeals(appeal, user)
          # User should be a judge
          root_task = RootTask.find_or_create_by!(appeal: appeal)

          JudgeDecisionReviewTask.create!(
            appeal: appeal,
            parent: root_task,
            assigned_to: user
          )
          $stdout.puts("You have created a Review task")
        end

        ########################################################
        # Creates Edge case data for the LegacyAppeals that have just been generated
        # Scenario 1
        def create_edge_case_task_for_legacy_appeals(appeal)
          root_task = RootTask.find_or_create_by!(appeal: appeal)
          rand_val = rand(100)

          case rand_val
          when 0..33
            hearing_task = HearingTask.create!(
              appeal: appeal,
              parent: root_task,
              assigned_to: Bva.singleton
            )
            ScheduleHearingTask.create!(
              appeal: appeal,
              parent: hearing_task,
              assigned_to: Bva.singleton
            )
          when 34..66
            hearing_task = HearingTask.create!(
              appeal: appeal,
              parent: root_task,
              assigned_to: Bva.singleton
            )
            ScheduleHearingTask.create!(
              appeal: appeal,
              parent: hearing_task,
              assigned_to: Bva.singleton
            ).update(status: "completed")
            AssignHearingDispositionTask.create!(
              appeal: appeal,
              parent: hearing_task,
              assigned_to: Bva.singleton
            )
          when 67..100
            hearing_task = HearingTask.create!(
              appeal: appeal,
              parent: root_task,
              assigned_to: Bva.singleton
            )
            ScheduleHearingTask.create!(
              appeal: appeal,
              parent: hearing_task,
              assigned_to: Bva.singleton
            ).update(status: "completed")
            assign_hearing_task = AssignHearingDispositionTask.create!(
              appeal: appeal,
              parent: hearing_task,
              assigned_to: Bva.singleton
            )
            TranscriptionTask.create!(
              appeal: appeal,
              parent: assign_hearing_task,
              assigned_to: Bva.singleton
            )
          end

          rand_val = rand(100)

          case rand_val
          when 0..25
            FoiaTask.create!(
              appeal: appeal,
              parent: root_task,
              assigned_to: Bva.singleton
            )

          when 26..50
            PowerOfAttorneyRelatedMailTask.create!(
              appeal: appeal,
              parent: root_task,
              assigned_to: Bva.singleton
            )

          when 51..75
            TranslationTask.create!(
              appeal: appeal,
              parent: root_task,
              assigned_to: Bva.singleton
            )

          when 76..100
            CongressionalInterestMailTask.create!(
              appeal: appeal,
              parent: root_task,
              assigned_to: Bva.singleton
            )
          end

          $stdout.puts("You have created a Hearing Task")
        end

        def initialize_root_task_for_legacy_appeals(appeal)
          RootTask.find_or_create_by!(appeal: appeal)
          $stdout.puts("You have set the Location to 81")
        end

        def create_task(task_type, appeal, user)
          if task_type == "HEARINGTASK"
            create_hearing_task_for_legacy_appeals(appeal)
          elsif task_type == "ATTORNEYTASK" && user.attorney_in_vacols?
            create_attorney_task_for_legacy_appeals(appeal, user)
          elsif task_type == "JUDGETASK" && user.judge_in_vacols?
            create_judge_task_for_legacy_appeals(appeal, user)
          elsif task_type == "REVIEWTASK" && user.judge_in_vacols?
            create_review_task_for_legacy_appeals(appeal, user)
          elsif task_type == "BRIEFF_CURLOC_81_TASK"
            initialize_root_task_for_legacy_appeals(appeal)
          elsif task_type == "SCENARIO1EDGE"
            create_edge_case_task_for_legacy_appeals(appeal)
          end
          # rubocop:enable
        end

        ########################################################
        # Create Postgres LegacyAppeals based on VACOLS Cases
        #
        # AND
        #
        # Create Postgres Request Issues based on VACOLS Issues
        def build_the_cases_in_caseflow(cases, task_type, user)
          vacols_ids = cases.map(&:bfkey)

          issues = VACOLS::CaseIssue.where(isskey: vacols_ids).group_by(&:isskey)
          cases.map do |case_record|
            AppealRepository.build_appeal(case_record).tap do |appeal|
              appeal.issues = (issues[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue.attributes) }
            end.save!
            appeal = LegacyAppeal.find_or_initialize_by(vacols_id: case_record.bfkey)
            create_task(task_type, appeal, user)
          end
        end
      end

      if Rails.env.development? || Rails.env.test?
        vets = Veteran.first(5)

        veterans_with_like_45_appeals = vets[0..12].pluck(:file_number) # local / test option for veterans

      else
        veterans_with_like_45_appeals = %w[011899917 011899918] # UAT option for veterans

      end

      $stdout.puts("Which type of tasks do you want to add to these Legacy Appeals?")
      $stdout.puts("Hint: Options include 'HearingTask', 'JudgeTask', 'AttorneyTask',
                     'ReviewTask', 'Scenario1edge' and 'Brieff_Curloc_81_Task'")
      task_type = $stdin.gets.chomp.upcase
      if task_type == "JUDGETASK" || task_type == "REVIEWTASK"
        $stdout.puts("Enter the CSS ID of a judge user that you want to assign these appeals to")

        if Rails.env.development? || Rails.env.test?
          $stdout.puts("Hint: Judge Options include 'BVARERDMAN'") # local / test option
        else
          $stdout.puts("Hint: Judge Options include 'CF_VLJ_283', 'CF_VLJTWO_283'") # UAT option
        end

        css_id = $stdin.gets.chomp.upcase
        user = User.find_by_css_id(css_id)

        fail ArgumentError, "User must be a Judge in Vacols for a #{task_type}", caller unless user.judge_in_vacols?
      elsif task_type == "ATTORNEYTASK"
        $stdout.puts("Which attorney do you want to assign the Attorney Task to?")

        if Rails.env.development? || Rails.env.test?
          $stdout.puts("Hint: Attorney Options include 'BVALSHIELDS'") # local / test option
        else
          $stdout.puts("Hint: Judge Options include 'CF_ATTN_283', 'CF_ATTNTWO_283'") # UAT option
        end

        css_id = $stdin.gets.chomp.upcase
        user = User.find_by_css_id(css_id)

        fail ArgumentError, "User must be an Attorney in Vacols for a #{task_type}", caller unless user.attorney_in_vacols?
      else # {Chooses default user to use for HearingTasks, Bfcurloc_81_Tasks, and Scenario1Edge Tasks}
        user = if Rails.env.development? || Rails.env.test?
                 User.find_by_css_id("FAKE USER") # local / test option
               else
                 User.find_by_css_id("CF_VLJTHREE_283") # UAT option
               end
      end

      fail ActiveRecord::RecordNotFound unless user

      # increment docket number for each case
      docket_number = 9_000_000

      veterans_with_like_45_appeals.each do |file_number|
        docket_number += 1
        LegacyAppealFactory.stamp_out_legacy_appeals(1, file_number, user, docket_number, task_type)
      end
      $stdout.puts("You have created Legacy Appeals")
    end
  end
end
