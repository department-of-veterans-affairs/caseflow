# frozen_string_literal: true

# to create 2 Legacy Appeals with hearing, run "bundle exec rake 'db:generate_legacy_hearing[1]'""
namespace :db do
  desc "Create a seed data for Legacy Appeals with hearing type"
  task :generate_legacy_hearing, [:number_of_appeals] => :environment do |_, args|
    num_appeals = args.number_of_appeals.to_i
    vacols_ids = []
    # RequestStore[:current_user] = User.find_by_css_id("BVASYELLOW")

    def create_legacy_appeals_with_open_schedule_hearing_task(regional_office, number_of_appeals_to_create, vacols_ids)
      # The offset should start at 100 to avoid collisions
      offsets = (100..(100 + number_of_appeals_to_create - 1)).to_a
      # Use a hearings user so the factories don't try to create one (and sometimes fail)
      user = User.find_by_css_id("BVASYELLOW")
      # Set this for papertrail when creating vacols_case
      RequestStore[:current_user] = user

      offsets.each do |offset|
        docket_number = "160000#{offset}"
        # next unless VACOLS::Folder.find_by(tinum: docket_number).nil?

        # Create the veteran for this legacy appeal
        vets = []
        (1..10).each do |_|
          vets << Veteran.find(Random.new.rand(1..Veteran.count))
        end

        veterans_file_number = vets[0..10].pluck(:file_number)
        vacols_titrnum = veterans_file_number[rand(veterans_file_number.count)]

        # Create some video and some travel hearings
        type = offset.even? ? "travel" : "video"

        # Create the folder, case, and appeal, there's a lot of retry logic in here
        # because the way FactoryBot sequences work isn't quite right for this case
        legacy_appeal = create_vacols_entries(vacols_titrnum, docket_number, regional_office, type)
        vacols_ids << legacy_appeal.vacols_id

        # Create the task tree, need to create each task like this to avoid user creation and index conflicts
        create_open_schedule_hearing_task_for_legacy(legacy_appeal, user)
      end
    end

    def create_video_vacols_case(vacols_titrnum, vacols_folder, correspondent)
      FactoryBot.create(
        :case,
        :video_hearing_requested,
        :type_original,
        correspondent: correspondent,
        bfcorlid: vacols_titrnum,
        bfcurloc: "CASEFLOW",
        folder: vacols_folder
      )
    end

    def create_travel_vacols_case(vacols_titrnum, vacols_folder, correspondent)
      FactoryBot.create(
        :case,
        :travel_board_hearing_requested,
        :type_original,
        correspondent: correspondent,
        bfcorlid: vacols_titrnum,
        bfcurloc: "CASEFLOW",
        folder: vacols_folder
      )
    end

    def create_vacols_entries(vacols_titrnum, docket_number, regional_office, type)
      # We need these retries because the sequence for FactoryBot comes out of
      # sync with what's in the DB. This just essentially updates the FactoryBot
      # sequence to match what's in the DB.
      # Note: Because the sequences in FactoryBot are global, these retrys won't happen
      # every time you call this, probably only the first time.
      retry_max = 100

      # Create the vacols_folder
      begin
        retries ||= 0
        vacols_folder = FactoryBot.create(:folder, tinum: docket_number, titrnum: vacols_titrnum)
      rescue ActiveRecord::RecordNotUnique
        retry if (retries += 1) < retry_max
      end

      # Create the correspondent (where the name in the UI comes from)
      begin
        retries ||= 0
        correspondent = FactoryBot.create(
          :correspondent,
          snamef: Faker::Name.first_name,
          snamel: Faker::Name.last_name,
          ssalut: ""
        )
      rescue ActiveRecord::RecordNotUnique
        retry if (retries += 1) < retry_max
      end

      # Create the vacols_case
      begin
        retries ||= 0
        if type == "video"
          vacols_case = create_video_vacols_case(vacols_titrnum, vacols_folder, correspondent)
        end
        if type == "travel"
          vacols_case = create_travel_vacols_case(vacols_titrnum, vacols_folder, correspondent)
        end
      rescue ActiveRecord::RecordNotUnique
        retry if (retries += 1) < retry_max
      end

      # Create the legacy_appeal, this doesn't fail with index problems, so no need to retry
      legacy_appeal = FactoryBot.create(
        :legacy_appeal,
        vacols_case: vacols_case,
        closest_regional_office: regional_office
      )
      FactoryBot.create(:available_hearing_locations, regional_office, appeal: legacy_appeal)

      # Return the legacy_appeal
      legacy_appeal
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
      # ScheduleHearingTask.create!(appeal: appeal, parent: root_task)
      FactoryBot.create(
        :schedule_hearing_task,
        :in_progress,
        assigned_to: user,
        assigned_by: user,
        parent: parent_hearing_task,
        appeal: legacy_appeal
      )
    end

    %w[RO17 RO21 RO26 RO27 RO40 RO45 RO46 RO47 RO55 RO58 RO59 RO63 RO62 RO49 RO38].each do |regional_office|
      create_legacy_appeals_with_open_schedule_hearing_task(regional_office, num_appeals, vacols_ids)
    end

    vacols_ids.each do |current_id|
      $stdout.puts("queue/appeals/#{current_id}")
    end
  end
end
