# frozen_string_literal: true

namespace :db do
  desc "Generates a smattering of legacy appeals with VACOLS cases that have special issues assocaited with them"
  task generate_legacy_appeals: :environment do
    class LegacyAppealFactory
      class << self
        # Stamping out appeals like mufflers!
        def stamp_out_legacy_appeals(num_appeals_to_create, file_number)
          veteran = Veteran.find_by_file_number(file_number)

          fail ActiveRecord::RecordNotFound unless veteran

          vacols_veteran_record = find_or_create_vacols_veteran(veteran)

          cases = Array.new(num_appeals_to_create).each_with_index.map do |_element, idx|
            Generators::Vacols::Case.create(
              corres_exists: true,
              case_issue_attrs: [
                Generators::Vacols::CaseIssue.case_issue_attrs.merge(special_issue_types(idx))
              ],
              folder_attrs: Generators::Vacols::Folder.folder_attrs.merge(
                custom_folder_attributes(vacols_veteran_record)
              ),
              case_attrs: {
                bfcorkey: vacols_veteran_record.stafkey,
                bfcorlid: vacols_veteran_record.slogid,
                bfkey: VACOLS::Folder.maximum(:ticknum).next
              }
            )
          end.compact

          build_the_cases_in_caseflow(cases)
        end

        def custom_folder_attributes(veteran)
          {
            titrnum: veteran.slogid,
            tiocuser: nil
          }
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
        # Create Postgres LegacyAppeals based on VACOLS Cases
        #
        # AND
        #
        # Create Postgres Request Issues based on VACOLS Issues
        def build_the_cases_in_caseflow(cases)
          vacols_ids = cases.map(&:bfkey)

          issues = VACOLS::CaseIssue.where(isskey: vacols_ids).group_by(&:isskey)

          cases.map do |case_record|
            AppealRepository.build_appeal(case_record).tap do |appeal|
              appeal.issues = (issues[appeal.vacols_id] || []).map { |issue| Issue.load_from_vacols(issue.attributes) }

              create_decision_tasks(appeal)
            end.save!
          end
        end

        # for demo only remove after
        def create_decision_tasks(appeal)
          admin = User.system_user
          RequestStore[:current_user] = admin
          judge = User.find_by_css_id('BVAAABSHIRE')
          att = User.find_by_css_id('BVASCASPER1')

          # case_assignment = OpenStruct.new(
          #   vacols_id: appeal.vacols_id,
          #   date_due: 1.day.ago,
          #   assigned_to_location_date: 5.days.ago,
          #   created_at: 6.days.ago,
          #   docket_date: nil
          # )

          root_task = RootTask.find_or_create_by!(appeal: appeal)
          root_task.assigned_to = judge
          root_task.save!
          # binding.pry
          task = AttorneyTask.new(
            appeal: appeal,
            parent: root_task,
            assigned_to: att,
            assigned_by: judge,
            instructions: "demo instructions"
          )
          task.save!

          acr = AttorneyCaseReview.new(
            appeal: appeal,
            reviewing_judge: judge,
            attorney: att,
            task: task,
            document_id: '22222222.2222',
            document_type: "draft_decision",
            work_product: "Decision",
            note: "Jeremy was here haha"
          )

          acr.save!
        end

        # MST is true for even indexes, and indexes that are multiples of 5. False for all other numbers.
        # PACT is true for odd idexes, and index that are also multiples of 5. False for all others.
        def special_issue_types(idx)
          {
            issmst: ((idx % 2).zero? || (idx % 5).zero?) ? "Y" : "N",
            isspact: (!(idx % 2).zero? || (idx % 5).zero?) ? "Y" : "N"
          }
        end
      end

      if Rails.env.development? || Rails.env.test?
        vets = Veteran.first(15)

        veterans_with_like_45_appeals = vets[0..12].pluck(:file_number)

        veterans_with_250_appeals = vets.last(3).pluck(:file_number)
      else
        veterans_with_like_45_appeals = %w[011899917 011899918 011899919 011899920 011899927
                                           011899928 011899929 011899930 011899937 011899938
                                           011899939 011899940]

        # veterans_with_250_appeals = %w[011899906 011899999]
      end

      veterans_with_like_45_appeals.each { |file_number| LegacyAppealFactory.stamp_out_legacy_appeals(1, file_number) }
      # veterans_with_250_appeals.each { |file_number| LegacyAppealFactory.stamp_out_legacy_appeals(250, file_number) }
    end
  end
end
