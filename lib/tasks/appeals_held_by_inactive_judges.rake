# frozen_string_literal: true

# to create legacy remanded appeals with AMA Tasks added
# run "bundle exec rake db:generate_appeals_held_by_inactive_judges"

namespace :appeals_held_by_inactive_judges do
    desc "Generates appeals that are ready to be distributed and have a hearing held by inelible judges"
    task generate_appeals_held_by_inactive_judges: :environment do
      class LegacyAppealFactory
        class << self
          # rubocop:disable Metrics/MethodLength
          def stamp_out_legacy_appeals_for_attorney(num_appeals_to_create, file_number, user, docket_number, task_type)
            bfcurloc = VACOLS::Staff.find_by(sdomainid: user.css_id).slogid

            veteran = Veteran.find_by_file_number(file_number)
            fail ActiveRecord::RecordNotFound unless veteran

            vacols_veteran_record = find_or_create_vacols_veteran(veteran)

            # Creates decass as they require an assigned_by field
            # which is grabbed from the Decass table (b/c it is an AttorneyLegacyTask)
            decass_creation = if task_type == "ATTORNEYTASK" && user&.attorney_in_vacols?
                                true
                              else false
                              end
            cases = Array.new(num_appeals_to_create).each_with_index.map do |_element, _idx|
              if Rails.env.development? || Rails.env.test?
                key = VACOLS::Folder.maximum(:ticknum).next
              else
                key = VACOLS::Folder.find_by_sql("SELECT max(to_number(ticknum)) as maxtick FROM FOLDER").first.maxtick.next
              end

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
          end
          # rubocop:enable Metrics/MethodLength

          def custom_folder_attributes(veteran, docket_number)
            {
              titrnum: veteran.slogid,
              tiocuser: nil,
              tinum: docket_number
            }
          end

          # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/AbcSize
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
          # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/AbcSize

          def custom_decass_attributes(key, user, decass_creation)
            attorney = if Rails.env.development? || Rails.env.test?
                         User.find_by_css_id("BVALSHIELDS") # local / test option
                       else
                         User.find_by_css_id("CF_ATTN_283") # UAT option
                       end
            if decass_creation
              {
                defolder: key,
                deatty: user.attorney_in_vacols? ? user.id : attorney.id,
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

          def create_review_and_hearing_task_for_legacy_appeals(appeal, user)
            # User should be a judge
            root_task = RootTask.find_or_create_by!(appeal: appeal)

            JudgeDecisionReviewTask.create!(
              appeal: appeal,
              parent: root_task,
              assigned_to: user
            )
            hearing_task = HearingTask.create!(
                appeal: appeal,
                parent: root_task,
                assigned_to: user
            )
            ScheduleHearingTask.create!(
                appeal: appeal,
                parent: hearing_task,
                assigned_to: user
            )
            $stdout.puts("You have created a Review and Hearing task.")
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

          def create_task(task_type, appeal, user)
            if task_type == "REVIEWTASK" && user.judge_in_vacols?
                create_review_task_for_legacy_appeals(appeal, user)
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

        task_type = "REVIEWTASK"

        $stdout.puts("Enter the CSS ID of a judge user that you want to assign these appeals to")

        if Rails.env.development? || Rails.env.test?
            $stdout.puts("Hint: Judge Options include 'BVARERDMAN'") # local / test option
        else
            $stdout.puts("Hint: Judge Options include 'CF_VLJ_283', 'CF_VLJTWO_283'") # UAT option
        end

        css_id = $stdin.gets.chomp.upcase
        user = User.find_by_css_id(css_id)

        fail ArgumentError, "User must be a Judge in Vacols for a #{task_type}", caller unless user.judge_in_vacols?

        fail ActiveRecord::RecordNotFound unless user

        # increment docket number for each case
        docket_number = 9_000_000

        veterans_with_like_45_appeals.each do |file_number|
          docket_number += 1
          LegacyAppealFactory.stamp_out_legacy_appeals_for_attorney(6, file_number, user, docket_number, task_type)
        end
        $stdout.puts("You have created Legacy Appeals")
      end
    end

    desc "given 'less' or 'more', create appeals that have been ready to be distributed for less/more than 60 days"
    task :create_appeals, [:more_or_less] => :environment do |_t, args|
      more_or_less = args[:more_or_less].upcase if args[:more_or_less]

      if more_or_less == "LESS"
        review_task_today = JudgeDecisionReviewTask.create(legacy_appeal: LegacyAppeal.last, created_at: Time.now)
      elsif more_or_less == "MORE"
        review_task_60_days_ago = JudgeDecisionReviewTask.create(legacy_appeal: LegacyAppeal.last, created_at: 61.days.ago)
        puts "Created a review task with a date more than 60 days ago."
      else
        STDOUT.puts("Please add 'more' or 'less' as an argument.")
      end
    end
  end
