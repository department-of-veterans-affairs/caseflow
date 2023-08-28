# frozen_string_literal: true

# to create legacy appeals with AMA Tasks added, run "bundle exec rake db:generate_legacy_appeals_with_tasks"
# then select an option between 'HearingTask', 'JudgeTask', 'AttorneyTask', 'ReviewTask', 'Scenario1edge' and 'Brieff_Curloc_81_Task'

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

          fail ActiveRecord::RecordNotFound unless veteran

          vacols_veteran_record = find_or_create_vacols_veteran(veteran)

          cases = Array.new(num_appeals_to_create).each_with_index.map do
            key = VACOLS::Folder.maximum(:ticknum).next
            Generators::Vacols::Case.create(
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
              decass_attrs: custom_decass_attributes(key, user, task_type)
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

        def custom_decass_attributes(key, user, task_type)
          if task_type == "ATTORNEYTASK" && user&.attorney_in_vacols?
            {
              defolder: key,
              deatty: user.id,
              dereceive: "2020-11-17 00:00:00 UTC"
            }
          else
            {}
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
            ).update(status: 'completed')
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
            ).update(status: 'completed')
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

        veterans_with_like_45_appeals = vets[0..12].pluck(:file_number)

      else
        veterans_with_like_45_appeals = %w[011899917 011899918]

      end

      $stdout.puts("Which type of tasks do you want to add to these Legacy Appeals?")
      $stdout.puts("Hint: Options include 'HearingTask', 'JudgeTask', 'AttorneyTask',
                     'ReviewTask', 'Scenario1edge' and 'Brieff_Curloc_81_Task'")
      task_type = $stdin.gets.chomp.upcase
      if task_type == "JUDGETASK" || task_type == "REVIEWTASK"
        $stdout.puts("Enter the CSS ID of a judge user that you want to assign these appeals to")
        $stdout.puts("Hint: Judge Options include 'BVAAABSHIRE', 'BVARERDMAN'")
        css_id = $stdin.gets.chomp.upcase
        user = User.find_by_css_id(css_id)
        fail ArgumentError, "User must be a Judge in Vacols for a #{task_type}", caller unless user.judge_in_vacols?
      elsif task_type == "ATTORNEYTASK"
        $stdout.puts("Which attorney do you want to assign the Attorney Task to?")
        $stdout.puts("Hint: Attorney Options include 'BVASCASPER1', 'BVARERDMAN', 'BVALSHIELDS'")
        css_id = $stdin.gets.chomp.upcase
        user = User.find_by_css_id(css_id)
        fail ArgumentError, "User must be an Attorney in Vacols for a #{task_type}", caller unless user.attorney_in_vacols?
      else
        user = User.find_by_css_id("FAKE USER")
      end

      fail ActiveRecord::RecordNotFound unless user

      # increment docket number for each case
      docket_number = 9_000_000

      veterans_with_like_45_appeals.each do |file_number|
        docket_number += 1
        LegacyAppealFactory.stamp_out_legacy_appeals(1, file_number, user, docket_number, task_type)
      end
      $stdout.puts("You have created Legacy Appeals")
      # veterans_with_250_appeals.each { |file_number| LegacyAppealFactory.stamp_out_legacy_appeals
      #                                  (250, file_number, user) }
    end
  end
end
