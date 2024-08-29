# frozen_string_literal: true

module Seeds
  class DemoLegacyCasesData < Base
    def initialize
      @seed_count = ENV['SEED_COUNT'].to_i
      @days_ago = ENV['DAYS_AGO'].to_i.days.ago
      @associated_judge = find_or_create_demo_seed_judge(ENV['JUDGE_CSS_ID'])
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      @seed_count.times do
        create_legacy_case
      end
    end

    def create_legacy_case
      Timecop.travel(@days_ago)
      veteran = create_demo_veteran_for_docket

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)

      vacols_case = create_video_vacols_case(veteran,
                                            correspondent,
                                            @associated_judge,
                                            @days_ago)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: demo_regional_office
      )

      create(:available_hearing_locations, demo_regional_office, appeal: legacy_appeal)
      Timecop.return
    end

    def create_video_vacols_case(veteran, correspondent, associated_judge, days_ago)
      create(
        :case,
        :aod,
        :tied_to_judge,
        :video_hearing_requested,
        :type_original,
        :ready_for_distribution,
        tied_judge: associated_judge,
        correspondent: correspondent,
        bfcorlid: "#{veteran.file_number}S",
        case_issues: create_list(:case_issue, 3, :compensation),
        bfd19: days_ago
      )
    end

    #TODO: put the below into helper module
    def random_demo_file_number_and_participant_id
      random_file_number = Random.rand(100_000_000...989_999_999)
      random_participant_id = random_file_number + 100000

      while find_demo_veteran(random_file_number)
        random_file_number += 2000
        random_participant_id += 2000
      end

      return random_file_number, random_participant_id
    end

    def find_or_create_demo_seed_judge(judge_ccs_id)
      unless judge_ccs_id.blank?
        User.find_by_css_id(judge_ccs_id) ||
          create(:user, :judge, :with_vacols_judge_record, css_id: judge_ccs_id, full_name: "Demo Judge " + judge_ccs_id)
      else
        User.find_by_css_id("QDEMOSEEDJ") ||
          create(:user, :judge, :with_vacols_judge_record, css_id: "QDEMOSEEDJ", full_name: "Demo Seed Judge")
      end
    end

    def demo_regional_office
      'RO17'
    end

    def find_demo_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end

    def create_demo_veteran_for_docket
      file_number, participant_id  = random_demo_file_number_and_participant_id
      create_demo_veteran(
        file_number: file_number,
        participant_id: participant_id
      )
    end

    def create_demo_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }

      Veteran.find_by_participant_id(params[:participant_id]) || create(:veteran, params.merge(options))
    end
  end
end
