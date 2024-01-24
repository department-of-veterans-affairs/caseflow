# frozen_string_literal: true

# This seed is intended to create specific test cases without changing the ID values for test data. Adding test
# cases to other seed files changes the order in which data is created and therefore the ID values of data,
# which can make regression testing difficult or change the ID values of known cases used in manual testing.

module Seeds
  class StaticTestCaseData < Base
    def initialize
      initial_id_values
    end

    def seed!
      cases_for_timely_calculations_on_das
      case_with_bad_decass_for_timeline_range_checks
      create_veterans_for_mpi_sfnod_updates
    end

    private

    def initial_id_values
      @file_number ||= 400_000_000
      @participant_id ||= 800_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1)) ||
            VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def create_veteran(options = {})
      @file_number += 1
      @participant_id += 1
      params = {
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      }
      create(:veteran, params.merge(options))
    end

    def cases_for_timely_calculations_on_das
      2.times do
        priority_case_with_only_attorney_task
        priority_case_with_attorney_task_children
        priority_case_with_attorney_rewrite_task
        priority_case_with_long_task_tree
        nonpriority_case_with_only_attorney_task
        nonpriority_case_with_attorney_task_children
        nonpriority_case_with_attorney_rewrite_task
        nonpriority_case_with_long_task_tree
        priority_case_with_only_attorney_task(37)
        priority_case_with_attorney_task_children(32)
        priority_case_with_attorney_rewrite_task(37)
        cavc_priority_case_with_only_attorney_task
        cavc_priority_case_with_attorney_task_children
        cavc_priority_case_with_attorney_rewrite_task
        priority_case_with_only_attorney_task(0)
      end
    end

    def priority_case_with_only_attorney_task(time_travel_days = 20)
      Timecop.travel(time_travel_days.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :advanced_on_docket_due_to_age,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def priority_case_with_attorney_task_children(time_travel_days = 15)
      Timecop.travel(time_travel_days.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :advanced_on_docket_due_to_age,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      create(:colocated_task,
             :translation,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:privacy_act_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:foia_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      appeal.tasks.of_type(:TranslationTask).first.completed!
      appeal.tasks.of_type(:PrivacyActTask).first.completed!
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def priority_case_with_attorney_rewrite_task(time_travel_days = 20)
      Timecop.travel(time_travel_days.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_judge_review,
                      :advanced_on_docket_due_to_age,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      judge_team = JudgeTeam.find_by(name: "BVAGSPORER")
      rewrite_task = create(:ama_attorney_rewrite_task,
                            parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
                            assigned_by: judge_team.users.first,
                            assigned_to: judge_team.users.last,
                            assigned_at: Time.zone.now)
      Timecop.return
      rewrite_task.completed!
    end

    def cavc_priority_case_with_only_attorney_task
      Timecop.travel(35.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :type_cavc_remand,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def cavc_priority_case_with_attorney_task_children
      Timecop.travel(32.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :type_cavc_remand,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      create(:colocated_task,
             :translation,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:privacy_act_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:foia_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      appeal.tasks.of_type(:TranslationTask).first.completed!
      appeal.tasks.of_type(:PrivacyActTask).first.completed!
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def cavc_priority_case_with_attorney_rewrite_task
      Timecop.travel(35.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_judge_review,
                      :type_cavc_remand,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      judge_team = JudgeTeam.find_by(name: "BVAGSPORER")
      rewrite_task = create(:ama_attorney_rewrite_task,
                            parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
                            assigned_by: judge_team.users.first,
                            assigned_to: judge_team.users.last,
                            assigned_at: Time.zone.now)
      Timecop.return
      rewrite_task.completed!
    end

    def nonpriority_case_with_only_attorney_task
      Timecop.travel(65.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def nonpriority_case_with_attorney_task_children
      Timecop.travel(62.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      create(:colocated_task,
             :translation,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:privacy_act_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      create(:foia_task,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      appeal.tasks.of_type(:TranslationTask).first.completed!
      appeal.tasks.of_type(:PrivacyActTask).first.completed!
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.return
      appeal.tasks.of_type(:AttorneyTask).first.completed!
    end

    def nonpriority_case_with_attorney_rewrite_task
      Timecop.travel(65.days.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_judge_review,
                      associated_judge: User.find_by_css_id("BVAGSPORER"),
                      issue_count: 1,
                      veteran: create_veteran)
      judge_team = JudgeTeam.find_by(name: "BVAGSPORER")
      rewrite_task = create(:ama_attorney_rewrite_task,
                            parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
                            assigned_by: judge_team.users.first,
                            assigned_to: judge_team.users.last,
                            assigned_at: Time.zone.now)
      Timecop.return
      rewrite_task.completed!
    end

    def priority_case_with_long_task_tree
      judge_team = JudgeTeam.find_by(name: "BVAEBECKER")
      Timecop.travel(15.months.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      :advanced_on_docket_due_to_age,
                      associated_judge: User.find_by_css_id("BVAEBECKER"),
                      associated_attorney: judge_team.users.last,
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :foia,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(5.months.from_now)
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :ihp,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(3.months.from_now)
      appeal.tasks.of_type(:IhpColocatedTask).first.completed!
      Timecop.travel(5.days.from_now)
      appeal.tasks.of_type(:AttorneyTask).first.completed!
       # Create AttorneyRewriteTask, this indicates appeal was sent back to the judge
      # and has been returned to attorney
      Timecop.travel(1.week.from_now)
      create(:ama_attorney_rewrite_task,
             parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
             assigned_by: judge_team.users.first,
             assigned_to: judge_team.users.last,
             assigned_at: Time.zone.now)
      # Create Other task under first AttorneyRewriteTask
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :other,
             parent: appeal.tasks.of_type(:AttorneyRewriteTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(2.weeks.from_now)
      appeal.tasks.of_type(:OtherColocatedTask).first.completed!
      Timecop.travel(1.weeks.from_now)
      appeal.tasks.of_type(:AttorneyRewriteTask).first.completed!
      # Create Second AttorneyRewriteTask
      Timecop.travel(1.week.from_now)
      create(:ama_attorney_rewrite_task,
             parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
             assigned_by: judge_team.users.first,
             assigned_to: judge_team.users.last,
             assigned_at: Time.zone.now)
      Timecop.travel(2.weeks.from_now)
      appeal.tasks.of_type(:AttorneyRewriteTask).second.completed!
      Timecop.return
    end

    def nonpriority_case_with_long_task_tree
      judge_team = JudgeTeam.find_by(name: "BVAEBECKER")
      Timecop.travel(15.months.ago)
      appeal = create(:appeal,
                      :direct_review_docket,
                      :with_request_issues,
                      :at_attorney_drafting,
                      associated_judge: User.find_by_css_id("BVAEBECKER"),
                      associated_attorney: judge_team.users.last,
                      issue_count: 1,
                      veteran: create_veteran)
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :foia,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(5.months.from_now)
      appeal.tasks.of_type(:FoiaTask).first.completed!
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :ihp,
             parent: appeal.tasks.of_type(:AttorneyTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(3.months.from_now)
      appeal.tasks.of_type(:IhpColocatedTask).first.completed!
      Timecop.travel(5.days.from_now)
      appeal.tasks.of_type(:AttorneyTask).first.completed!
       # Create AttorneyRewriteTask, this indicates appeal was sent back to the judge
      # and has been returned to attorney
      Timecop.travel(1.week.from_now)
      create(:ama_attorney_rewrite_task,
             parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
             assigned_by: judge_team.users.first,
             assigned_to: judge_team.users.last,
             assigned_at: Time.zone.now)
      # Create Other task under first AttorneyRewriteTask
      Timecop.travel(1.week.from_now)
      create(:colocated_task,
             :other,
             parent: appeal.tasks.of_type(:AttorneyRewriteTask).first,
             assigned_at: Time.zone.now)
      Timecop.travel(2.weeks.from_now)
      appeal.tasks.of_type(:OtherColocatedTask).first.completed!
      Timecop.travel(1.weeks.from_now)
      appeal.tasks.of_type(:AttorneyRewriteTask).first.completed!
      # Create Second AttorneyRewriteTask
      Timecop.travel(1.week.from_now)
      create(:ama_attorney_rewrite_task,
             parent: appeal.tasks.of_type(:JudgeDecisionReviewTask).first,
             assigned_by: judge_team.users.first,
             assigned_to: judge_team.users.last,
             assigned_at: Time.zone.now)
      Timecop.travel(2.weeks.from_now)
      appeal.tasks.of_type(:AttorneyRewriteTask).second.completed!
      Timecop.return
    end

    # DECASS values from factorybot have 00:00:00 for timestamp which is desired in this case
    def case_with_bad_decass_for_timeline_range_checks
      Time.zone = 'EST'
      vet = create_veteran
      cf_judge = User.find_by_css_id("BVABDANIEL") || create(:user, :judge, :with_vacols_judge_record)
      cf_atty = User.find_by_css_id("BVABBLOCK") || create(:user, :with_vacols_attorney_record)
      judge = VACOLS::Staff.find_by_css_id(cf_judge.css_id)
      atty = VACOLS::Staff.find_by_css_id(cf_atty.css_id)
      vc = create(:case, :assigned, user: cf_judge, bfcorlid: "#{vet.file_number}S")
      create(:legacy_appeal, vacols_case: vc)
      create(:priorloc, lockey: vc.bfkey, locdin: 5.weeks.ago, locdout: 5.weeks.ago - 1.day, locstout: judge.slogid, locstto: judge.slogid)
      create(:priorloc, lockey: vc.bfkey, locdin: 4.weeks.ago, locdout: 5.weeks.ago, locstout: judge.slogid, locstto: "CASEFLOW_judge")
      create(:priorloc, lockey: vc.bfkey, locdin: 3.weeks.ago, locdout: 4.weeks.ago, locstout: "CASEFLOW_judge", locstto: judge.slogid)
      create(:priorloc, lockey: vc.bfkey, locdin: 2.weeks.ago, locdout: 3.weeks.ago, locstout: judge.slogid, locstto: atty.slogid)
      create(:priorloc, lockey: vc.bfkey, locdin: 1.week.ago, locdout: 2.weeks.ago, locstout: atty.slogid, locstto: "CASEFLOW_atty")
      create(:priorloc, lockey: vc.bfkey, locdin: Time.zone.now, locdout: 1.week.ago, locstout: "CASEFLOW_atty", locstto: atty.slogid)
      create(:priorloc, lockey: vc.bfkey, locdout: Time.zone.now, locstout: atty.slogid, locstto: judge.slogid)
    end

    def create_veterans_for_mpi_sfnod_updates
      veteran_data_for_mpi_nod_updates.each do |record|
        corres = create(:correspondent, record)
        # bfcorlid must end in S so that caseflow can search for it
        create(:case, bfcorlid: "#{corres.ssn}S", correspondent: corres)
        store_veteran_in_redis_cache(corres) if Rails.env.development? || Rails.env.test?
      end
    end

    def store_veteran_in_redis_cache(corres)
      # map values from CORRES to their keys in BGS Service
      # DOB format needs to be mm/dd/yyyy to match BGS records
      attrs = {
        address_line1: corres.saddrst1,
        city: corres.saddrcty,
        date_of_birth: corres.sdob.to_date.strftime("%m/%d/%Y"),
        file_number: corres.ssn,
        first_name: corres.snamef,
        last_name: corres.snamel,
        middle_name: corres.snamemi,
        phone_number_one: corres.stelh,
        salutation_name: corres.ssalut,
        ssn: corres.ssn,
        state: corres.saddrstt,
        zip_code: corres.saddrzip,
        sex: corres.sgender
      }

      # build and store veteran in redis
      Generators::Veteran.build(attrs)
    end

    def veteran_data_for_mpi_nod_updates
      [
        { stafkey: "1234567891", susrtyp: "VETERAN", ssalut: "", snamef: "MIKE", snamel: "CLEMONS", saddrst1: "614 SE 13ST", saddrcty: "FT.Lauderdale", saddrstt: "FL", saddrzip: "33304", stelh: "405-667-9832", sactive: "A", ssn: "867895432", sdob: "1970-12-12", sgender: "M" },
        { stafkey: "1234567892", susrtyp: "VETERAN", ssalut: "", snamef: "Gregory", snamel: "Thomas", saddrst1: "521 N Fort Lauderdale Beach Blvd", saddrcty: "FT.Lauderdale", saddrstt: "FL", saddrzip: "33304", stelh: "571-679-5555", sactive: "A", ssn: "678849874", sdob: "1955-06-06", sgender: "M" },
        { stafkey: "1234567893", susrtyp: "VETERAN", ssalut: "", snamef: "Franklin", snamel: "Thomas", saddrst1: "1417 SW 41st Ave", saddrcty: "FT.Lauderdale", saddrstt: "FL", saddrzip: "33317", stelh: "954-863-5555", sactive: "A", ssn: "784456431", sdob: "1965-07-06", sgender: "M" },
        { stafkey: "1234567894", susrtyp: "VETERAN", ssalut: "", snamef: "George", snamel: "Thomas", saddrst1: "1402 NW 5th St", saddrcty: "FT.Lauderdale", saddrstt: "FL", saddrzip: "33311", stelh: "954-871-5555", sactive: "A", ssn: "673489455", sdob: "1968-07-06", sgender: "M" },
        { stafkey: "1234567895", susrtyp: "VETERAN", ssalut: "", snamef: "Ryan", snamel: "Thompson", saddrst1: "4156 New York Ave", saddrcty: "St.Cloud", saddrstt: "FL", saddrzip: "34744", stelh: "567-447-8711", sactive: "A", ssn: "748997154", sdob: "1997-04-28", sgender: "M" },
        { stafkey: "1234567896", susrtyp: "VETERAN", ssalut: "", snamef: "Tannis", snamel: "Biggum", saddrst1: "3103 N Fort Valley Rd", saddrcty: "Flagstaff", saddrstt: "AZ", saddrzip: "86001", stelh: "703-376-4734", sactive: "A", ssn: "448167748", sdob: "1998-03-20", sgender: "F" },
        { stafkey: "1234567897", susrtyp: "VETERAN", ssalut: "", snamef: "Patrik", snamel: "Boolay", saddrst1: "824 S Colonial", saddrcty: "Roswell", saddrstt: "GA", saddrzip: "30009", stelh: "867-555-7841", sactive: "A", ssn: "334568484", sdob: "1976-07-07", sgender: "F" },
        { stafkey: "1234567899", susrtyp: "VETERAN", ssalut: "", snamef: "HIENRIK", snamel: "TESTMAN", saddrst1: "1931 S Federal HWY", saddrcty: "Ft. Lauderdale ", saddrstt: "FL", saddrzip: "33316", stelh: "954-555-8671", sactive: "A", ssn: "764889132", sdob: "1978-01-01", sgender: "M" },
        { stafkey: "1234567898", susrtyp: "VETERAN", ssalut: "", snamef: "Johnathan", snamel: "Walker", saddrst1: "8849 Washington St", saddrcty: "Ft.Lauderdale", saddrstt: "FL", saddrzip: "33304", stelh: "745-555-5512", sactive: "A", ssn: "555164875", sdob: "1979-06-06", sgender: "M" }
      ]
    end
  end
end
