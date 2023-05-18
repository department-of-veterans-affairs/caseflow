# frozen_string_literal: true

# When using this factory, passing in a VACOLS::Case object as vacols_case is the preferred method. The
# :case factory in the factories/vacols is used to generate VACOLS cases. This ensures that the correct
# associations exist between VACOLS and Caseflow, and that the BFKEY of the case is unique.

FactoryBot.define do
  factory :legacy_appeal do
    transient do
      vacols_case { nil }
      veteran_address { nil }
      appellant_address { nil }
    end

    vacols_id { vacols_case&.bfkey || "123456" }
    vbms_id { vacols_case&.bfcorlid }

    after(:create) do |appeal, evaluator|
      if evaluator.veteran_address.present?
        vbms_id = appeal.sanitized_vbms_id
        veteran = Veteran.find_by(file_number: vbms_id) || create(:veteran, file_number: vbms_id)

        (BGSService.address_records ||= {}).update(veteran.participant_id => evaluator.veteran_address)
      end

      if evaluator.appellant_address.present? && appeal.appellant_ssn.present?
        # Creating a veteran has a side effect of populating `BGSService.veteran_store`.
        # BGS should be setup to return the appellant's participant ID from their SSN.
        appellant = create(:veteran, ssn: appeal.appellant_ssn)

        (BGSService.address_records ||= {}).update(appellant.participant_id => evaluator.appellant_address)
      end
    end

    trait :with_schedule_hearing_tasks do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)
      end
    end

    trait :with_root_task do
      after(:create) do |appeal, _evaluator|
        RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
      end
    end

    trait :with_completed_root_task do
      after(:create) do |appeal, _evaluator|
        task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        task.update!(status: "completed")
      end
    end

    trait :with_cancelled_root_task do
      after(:create) do |appeal, _evaluator|
        task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        task.update!(status: "cancelled")
      end
    end

    trait :with_active_ihp_colocated_task do
      after(:create) do |appeal, _evaluator|
        org = Organization.find_by(type: "Vso")
        org ||= create(:vso)
        create(:colocated_task, :ihp, appeal: appeal, assigned_to: org)
      end
    end

    trait :with_completed_ihp_colocated_task do
      after(:create) do |appeal, _evaluator|
        org = Organization.find_by(type: "Vso")
        org ||= create(:vso)
        create(:colocated_task, :ihp, appeal: appeal, assigned_to: org)
        ihp_task = appeal.tasks.find_by(type: "IhpColocatedTask")
        ihp_task.update!(status: Constants.TASK_STATUSES.completed)
      end
    end

    trait :with_judge_assign_task do
      after(:create) do |appeal, _evaluator|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        judge = User.find_or_create_by(css_id: "BVAAABSHIRE", station_id: 101)
        JudgeAssignTask.create!(appeal: appeal,
                                parent: root_task,
                                assigned_at: Time.zone.now,
                                assigned_to: judge)
      end
    end

    trait :with_veteran do
      after(:create) do |legacy_appeal, evaluator|
        file_number = legacy_appeal.veteran_file_number
        veteran = Veteran.find_by(file_number: legacy_appeal.veteran_file_number) || create(
          :veteran,
          first_name: "Bob",
          last_name: "Smith",
          file_number: file_number
        )

        if evaluator.vacols_case
          evaluator.vacols_case.correspondent.snamef = veteran.first_name
          evaluator.vacols_case.correspondent.snamel = veteran.last_name
          evaluator.vacols_case.correspondent.ssalut = "PhD"
          evaluator.vacols_case.correspondent.save
        end
      end
    end

    trait :with_veteran_address do
      veteran_address do
        {
          addrs_one_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1,
          addrs_two_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_2,
          addrs_three_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_3,
          city_nm: FakeConstants.BGS_SERVICE.DEFAULT_CITY,
          cntry_nm: FakeConstants.BGS_SERVICE.DEFAULT_COUNTRY,
          postal_cd: FakeConstants.BGS_SERVICE.DEFAULT_STATE,
          zip_prefix_nbr: FakeConstants.BGS_SERVICE.DEFAULT_ZIP,
          ptcpnt_addrs_type_nm: "Mailing"
        }
      end
    end
  end
end
