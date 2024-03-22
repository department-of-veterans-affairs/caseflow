# frozen_string_literal: true

class Judge
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def attorneys
    JudgeTeam.for_judge(user).try(:attorneys) || []
  end

  class << self
    def repository
      JudgeRepository
    end

    def list_all
      Rails.cache.fetch("#{Rails.env}_list_of_judges_from_vacols") do
        repository.find_all_judges
      end
    end

    def list_all_hashes
      Rails.cache.fetch("#{Rails.env}_hashes_of_judges_from_vacols") do
        list_all.map do |judge|
          {
            label: judge.full_name,
            value: judge.id
          }
        end
      end
    end

    def list_all_with_name_and_id
      # idt requires full name and sattyid
      Rails.cache.fetch("#{Rails.env}_list_of_judges_from_vacols_with_name_and_id") do
        repository.find_all_judges_with_name_and_id
      end
    end
  end
end
