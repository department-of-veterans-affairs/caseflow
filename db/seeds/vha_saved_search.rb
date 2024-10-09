# frozen_string_literal: true

# These seeds are for data into saved search table.

module Seeds
  class VhaGenerateTaskReport < Base
    NUMBER_OF_RECORDS_TO_CREATE = 5

    def seed!
      RequestStore[:current_user] = User.system_user
      create_seeds_for_generate_task_report_one
      create_seeds_for_generate_task_report_two
      create_seeds_for_generate_task_report_three
      create_seeds_for_generate_task_report_four
    end

    def create_seeds_for_generate_task_report_one
      create(:saved_search)
    end


    def create_seeds_for_generate_task_report_two
      create(:saved_search, :saved_search_one)
    end

    def create_seeds_for_generate_task_report_three
      create(:saved_search, :saved_search_two)
    end

    def create_seeds_for_generate_task_report_four
      create(:saved_search, :saved_search_three)
    end
  end
end
