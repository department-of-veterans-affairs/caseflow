# frozen_string_literal: true

# to create 2 Legacy Appeals with hearing, run "bundle exec rake 'db:generate_legacy_hearing[1]'""

namespace :db do
  desc "Create a seed data for Legacy Appeals with hearing type"
  task :generate_legacy_hearing, [:number_of_appeals] => :environment do |_, args|
    num_appeals = args.number_of_appeals.to_i
    legacy_ids = []
    user = User.system_user
    RequestStore[:current_user] = user

    def create_legacy_appeals_with_open_schedule_hearing_task(regional_office, number_of_appeals_to_create, legacy_ids)
      offsets = (100..(100 + number_of_appeals_to_create - 1)).to_a

      offsets.each do |offset|
        docket_number = "160000#{offset}"

        # Create the veteran for this legacy appeal
        vets = Veteran.order(Arel.sql("RANDOM()")).first(10)

        veterans_file_number = vets[0..10].pluck(:file_number)
        vacols_titrnum = veterans_file_number[rand(veterans_file_number.count)]

        create_vacols_entries(vacols_titrnum, docket_number, regional_office, legacy_ids, number_of_appeals_to_create)
      end
    end

    def find_or_create_vacols_veteran(veteran)
      # Being naughty and calling a private method (it'd be cool to have this be public...)
      vacols_veteran_record = VACOLS::Correspondent.send(:find_veteran_by_ssn, veteran.ssn).first

      return vacols_veteran_record if vacols_veteran_record

      Generators::VACOLS::Correspondent.create(
        Generators::VACOLS::Correspondent.correspondent_attrs.merge(
          ssalut: veteran.name_suffix,
          snamef: veteran.first_name,
          snamemi: veteran.middle_name,
          snamel: veteran.last_name,
          slogid: LegacyAppeal.convert_file_number_to_vacols(veteran.file_number)
        )
      )
    end

    def custom_folder_attributes(veteran, docket_number)
      {
        titrnum: veteran.slogid,
        tiocuser: nil,
        tinum: docket_number
      }
    end

    def custom_hearing_attributes(type)
      { hearing_type: type }
    end

    def other_params(vacols_veteran_record, key, type, regional_office)
      {
        bfcorkey: vacols_veteran_record.stafkey,
        bfcorlid: vacols_veteran_record.slogid,
        bfkey: key,
        bfcurloc: "CASEFLOW",
        bfmpro: "ACT",
        bfddec: nil,
        bfregoff: regional_office,
        bfhr: 2,
        bfdocind: type
      }
    end

    def build_the_cases_in_caseflow(cases)
      vacols_ids = cases.map(&:bfkey)
      issues = VACOLS::CaseIssue.where(isskey: vacols_ids).group_by(&:isskey)

      cases.map do |case_record|
        AppealRepository.build_appeal(case_record).tap do |appeal|
          appeal.issues = (issues[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue.attributes) }
        end.save!
        legacy_appeal = LegacyAppeal.last
        create_open_schedule_hearing_task_for_legacy(legacy_appeal, RequestStore[:current_user])
        legacy_appeal
      end
    end

    def create_open_schedule_hearing_task_for_legacy(legacy_appeal, user)
      root_task = RootTask.create!(appeal: legacy_appeal)

      distribution_task = DistributionTask.create!(
        appeal: legacy_appeal,
        parent: root_task
      )
      parent_hearing_task = HearingTask.create!(
        assigned_by: user,
        assigned_to: user,
        parent: distribution_task,
        appeal: legacy_appeal
      )
      schedule_hearing_task = ScheduleHearingTask.create!(
        status: "assigned",
        assigned_to: user,
        assigned_by: user,
        parent: parent_hearing_task,
        appeal: legacy_appeal
      )
      schedule_hearing_task.update(status: "in_progress")
    end

    def create_vacols_entries(vacols_titrnum, docket_number, regional_office, legacy_ids, num_appeals_to_create)
      veteran = Veteran.find_by_file_number(vacols_titrnum)
      vacols_veteran_record = find_or_create_vacols_veteran(veteran)

      # Create some video and some travel hearings
      type = docket_number.to_i.even? ? "T" : "V"

      cases = Array.new(num_appeals_to_create).each_with_index.map do |_element|
        key = VACOLS::Case.pluck(:bfkey).map(&:to_i).max + 1
        Generators::VACOLS::Case.create(
          corres_exists: true,
          folder_attrs: Generators::VACOLS::Folder.folder_attrs.merge(
            custom_folder_attributes(vacols_veteran_record, docket_number.to_s)
          ),
          case_hearing_attrs: [Generators::VACOLS::CaseHearing.case_hearing_attrs.merge(
            custom_hearing_attributes(type)
          )],
          case_attrs: other_params(vacols_veteran_record, key, type, regional_office)
        )
      end.compact
      legacy_appeal = build_the_cases_in_caseflow(cases)
      legacy_ids << legacy_appeal[0].vacols_id
    end

    %w[RO17 RO21 RO26 RO27 RO40 RO45 RO46 RO47 RO55 RO58 RO59 RO63 RO62 RO49 RO38].each do |regional_office|
      create_legacy_appeals_with_open_schedule_hearing_task(regional_office, num_appeals, legacy_ids)
    end

    legacy_ids.each do |current_id|
      $stdout.puts("queue/appeals/#{current_id}")
    end
  end
end
