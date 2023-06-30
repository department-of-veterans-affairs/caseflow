# frozen_string_literal: true

# to create legacy appeals with MST/PACT issues, run "bundle exec rake 'db:generate_legacy_appeals[true]'""
# to create without, run "bundle exec rake db:generate_legacy_appeals"
namespace :db do
  desc "Generates a smattering of legacy appeals with VACOLS cases that have special issues assocaited with them"
  task :generate_legacy_appeals, [:add_special_issues] => :environment do |_, args|
    ADD_SPECIAL_ISSUES = args.add_special_issues == "true"
    class LegacyAppealFactory
      class << self
        # Stamping out appeals like mufflers!
        def stamp_out_legacy_appeals(num_appeals_to_create, file_number, user, docket_number)
          veteran = Veteran.find_by_file_number(file_number)

          fail ActiveRecord::RecordNotFound unless veteran

          vacols_veteran_record = find_or_create_vacols_veteran(veteran)

          cases = Array.new(num_appeals_to_create).each_with_index.map do |_element, idx|
            key = VACOLS::Folder.maximum(:ticknum).next
            Generators::Vacols::Case.create(
              corres_exists: true,
              case_issue_attrs: [
                Generators::Vacols::CaseIssue.case_issue_attrs.merge(ADD_SPECIAL_ISSUES ? special_issue_types(idx) : {})
              ],
              folder_attrs: Generators::Vacols::Folder.folder_attrs.merge(
                custom_folder_attributes(vacols_veteran_record, docket_number.to_s)
              ),
              case_attrs: {
                bfcorkey: vacols_veteran_record.stafkey,
                bfcorlid: vacols_veteran_record.slogid,
                bfkey: key,
                bfcurloc: VACOLS::Staff.find_by(sdomainid: user.css_id).slogid,
                bfmpro: "ACT",
                bfddec: nil,
              },
              staff_attrs: {
                sattyid: user.id,
                sdomainid: user.css_id
              },
              decass_attrs: {
                defolder: key,
                deatty: user.id,
                dereceive: "2020-11-17 00:00:00 UTC"
              }
            )
          end.compact

          build_the_cases_in_caseflow(cases)
        end

        def custom_folder_attributes(veteran, docket_number)
          {
            titrnum: veteran.slogid,
            tiocuser: nil,
            tinum: docket_number
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
            end.save!
          end
        end

        # MST is true for even indexes, and indexes that are multiples of 5. False for all other numbers.
        # PACT is true for odd idexes, and index that are also multiples of 5. False for all others.
        def special_issue_types(idx)
          {
            issmst: ((idx % 2).zero? || (idx % 5).zero?) ? "Y" : "N",
            isspact: (!(idx % 2).zero? || (idx % 5).zero?) ? "Y" : "N",
            issdc: nil
          }
        end
      end

      if Rails.env.development? || Rails.env.test?
        # vets = Veteran.first(15)

        # veterans_with_like_45_appeals = vets[0..12].pluck(:file_number)

        # veterans_with_250_appeals = vets.last(3).pluck(:file_number)


        # remove under after done testing
        vets = Veteran.first(3)
        veterans_with_few_appeals = vets[0..3].pluck(:file_number)
      else
        veterans_with_like_45_appeals = %w[011899917 011899918 011899919 011899920 011899927
                                           011899928 011899929 011899930 011899937 011899938
                                           011899939 011899940]

        # veterans_with_250_appeals = %w[011899906 011899999]
      end

      # request CSS ID for task assignment
      STDOUT.puts("Enter the CSS ID of the user that you want to assign these appeals to")
      STDOUT.puts("Hint: an Attorney User for demo env is BVASCASPER1, and UAT is TCASEY_JUDGE and CGRAHAM_JUDGE")
      css_id = STDIN.gets.chomp.upcase
      user = User.find_by_css_id(css_id)

      fail ActiveRecord::RecordNotFound unless user

      # increment docket number for each case
      docket_number = 9_000_000

      veterans_with_few_appeals.each do |file_number|
        docket_number += 1
        LegacyAppealFactory.stamp_out_legacy_appeals(1, file_number, user, docket_number)
      end
      # veterans_with_250_appeals.each { |file_number| LegacyAppealFactory.stamp_out_legacy_appeals(250, file_number, user) }
    end
  end
end
