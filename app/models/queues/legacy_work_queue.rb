# frozen_string_literal: true

class LegacyWorkQueue
  include ActiveModel::Model
  class << self
    def tasks_for_user(user)
      # puts "------------------when is this called-----------------"
      # byebug
      vacols_tasks = repository.tasks_for_user(user.css_id)
      tasks_from_vacols_tasks(vacols_tasks, user)
    end

    def tasks_by_appeal_id(appeal_id)
      vacols_tasks = repository.tasks_for_appeal(appeal_id)
      tasks_from_vacols_tasks(vacols_tasks)
    end

    def repository
      QueueRepository
    end

    private

    def tasks_from_vacols_tasks(vacols_tasks, user = nil)
      return [] if vacols_tasks.empty?

      # vacols_ids = vacols_tasks.map(&:vacols_id)
      vacols_appeals = repository.appeals_by_vacols_ids(vacols_tasks.map(&:vacols_id))

      # puts "inside tasks from vacols tasks"
      # puts vacols_appeals.class
      # puts vacols_appeals.inspect

      # ActiveRecord::Associations::Preloader
      # Attempt at preloading to avoid individual DB queries for each record
      # Should help speed it up on average I think. Will also reduce database queries which is generally good.
      preloader = ActiveRecord::Associations::Preloader.new
      preload_associations = [
        :appeal_views,
        :work_mode,
        :special_issue_list,
        :latest_informal_hearing_presentation_task
      ]
      # preloader.preload(vacols_appeals, preload_associations)

      # Pluck doesn't work. That's unfrotunate
      # veteran_ssns = vacols_appeals.pluck(:veteran_ssn)
      veteran_ssns = vacols_appeals.map(&:veteran_ssn)
      # puts veteran_ssns.count
      # TODO: This makes a big assumption that it's an SSN.
      # Borrowed from veteran finder as a start
      # However this is a bit off since the query in vet finder doesn't want file numbers that are SSNs
      # Personally I don't care, since it eventually falls back to file number as well and this proof of concept
      veterans_hash = {}
      # veterans_hash = Veteran.where(ssn: veteran_ssns).or(Veteran.where(file_number: veteran_ssns)).index_by(&:ssn)
      Veteran.where(ssn: veteran_ssns).or(Veteran.where(file_number: veteran_ssns)).each do |veteran|
        # forget it just double up for testing concept
        # Are neither of these fields bgs fields? It doesn't slow this block of code down,
        # but the serializer is still slow even after bulk loading because of redis calls
        veterans_hash[veteran.ssn] = veteran
        veterans_hash[veteran.file_number] = veteran
      end

      # puts "veterans hash count: #{veterans_hash.count}"
      # puts veterans_hash.inspect
      # puts veterans_hash.inspect
      # puts veterans_hash.count

      # This not the fastest way to do this, but it seems to work
      vacols_appeals.each do |appeal|
        # appeal.instance_variable_set(:@veteran, veterans_hash[appeal.veteran_ssn])
        found_veteran = veterans_hash[appeal.veteran_ssn]
        # puts "Matched veteran SSN: #{found_veteran&.ssn}"
        next unless found_veteran

        appeal.veteran = found_veteran
        appeal.veteran_file_number_fast = found_veteran.file_number
        appeal.veteran_date_of_death_fast = found_veteran.date_of_death
      end

      # vacols_appeals.each(&:veteran)

      # Custom preload block to attempt to preload veterans as well.
      # This doesn't seem to work for some reason. Maybe use .tap?
      # preloader.preload(vacols_appeals, preload_associations) do |appeal|
      #   # puts "in preload. Do I have access to veterans_hash? #{veterans_hash.count}"
      #   # appeal.veteran = VeteranFinder.find_best_match(appeal.sanitized_vbms_id)
      #   appeal.veteran = veterans_hash[appeal.veteran_ssn]
      # end

      preloader.preload(vacols_appeals, preload_associations)
      # preloader.preload(appeals, preload_associations)

      vacols_tasks.zip(vacols_appeals).map do |task, appeal|
        user = validate_or_create_user(user, task.assigned_to_css_id)

        task_class = AttorneyLegacyTask
        # If the user is a pure_judge (not acting judge), they are only assigned JudgeLegacyTasks.
        # If the user is an acting judge, assume any case that already has a decision doc is assigned to them as a judge
        if user&.pure_judge_in_vacols? ||
           (user&.acting_judge_in_vacols? && appeal.assigned_to_acting_judge_as_judge?(user))
          task_class = JudgeLegacyTask
        end

        task_class.from_vacols(task, appeal, user)
      end
    end

    def validate_or_create_user(user, css_id)
      # Why does this have to be a station_id of 101 to avoid a DB or cache call?????
      if css_id && (css_id == user&.css_id) && (user.station_id == User::BOARD_STATION_ID)
        user
      elsif css_id
        User.find_by_css_id_or_create_with_default_station_id(css_id)
      end
    end
  end
end
