# frozen_string_literal: true

module Seeds
  class DemoAmaAodHearingData < Base
    def initialize
      @seed_count = ENV["SEED_COUNT"].to_i
      @days_ago = ENV["DAYS_AGO"].to_i.days.ago
      @hearing_judge = find_or_create_demo_seed_judge(ENV['JUDGE_CSS_ID'])
      @disposition = ENV["DISPOSITION"]
      @hearing_type = ENV["HEARING_TYPE"]
      @hearing_date = ENV["HEARING_DATE"]
      @aod_based_on_age = ENV["AOD_BASED_ON_AGE"]
      @closest_regional_office = ENV["CLOSEST_REGIONAL_OFFICE"]
      @uuid = ENV["UUID"]
      @docket = ENV["DOCKET"]
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      @seed_count.times do
        create_ama_aod_hearing
      end
    end

    def create_ama_aod_hearing
      Timecop.travel(@days_ago)
      @appeal = create(
          :appeal,
          :hearing_docket,
          :with_post_intake_tasks,
          :advanced_on_docket_due_to_age,
          :held_hearing_and_ready_to_distribute,
          :tied_to_judge,
          veteran: create_demo_veteran_for_docket,
          receipt_date: @days_ago,
          tied_judge: @hearing_judge,
          adding_user: User.first,
        )
      update_data
      Timecop.return
    end

    def update_data
      appeal_data = {}
      appeal_data[:aod_based_on_age] = @aod_based_on_age if @aod_based_on_age.present?
      appeal_data[:closest_regional_office] = @closest_regional_office if @closest_regional_office.present?
      appeal_data[:uuid] = @uuid if @uuid.present?
      appeal_data[:docket_type] = @docket if @docket.present?
      @appeal.update!(appeal_data) if appeal_data.present?

      hearing = @appeal.hearings.first
      if hearing
        hearing.update!(disposition: @disposition) if @disposition.present?
        hearing_day = hearing.hearing_day
        if hearing_day
          hearing_day.request_type = @hearing_type if @hearing_type.present?
          hearing_day.scheduled_for = @hearing_date if @hearing_date.present?
          hearing_day.save!
        end
      end
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
