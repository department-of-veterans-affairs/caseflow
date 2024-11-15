# frozen_string_literal: true

# Motion to Vacate seeds

module Seeds
  class MTV < Base
    MOTION_DISPOSITIONS = %w[denied dismissed granted].freeze
    NOT_GRANTED_MOTION_DISPOSITIONS = %w[denied dismissed].freeze
    VACATE_TYPES = %w[straight_vacate vacate_and_de_novo vacate_and_readjudication].freeze

    def initialize
      file_number_initial_value
    end

    def seed!
      setup_motion_to_vacate_appeals
    end

    private

    # maintains previous file number values while allowing for reseeding
    def file_number_initial_value
      @file_number ||= 100_000
      # this seed file creates 40 new veterans on each run, 100 is sufficient margin to add more data
      @file_number += 100 while Veteran.find_by(file_number: format("%<n>09d", n: @file_number))
      @file_number
    end

    def create_decided_appeal(mtv_judge, drafting_attorney)
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      appeal = create(
        :appeal,
        :dispatched,
        associated_judge: mtv_judge,
        associated_attorney: drafting_attorney,
        number_of_claimants: 1,
        veteran_file_number: veteran.file_number,
        stream_type: Constants.AMA_STREAM_TYPES.original
      )
      create_appeal_issues(appeal)

      appeal
    end

    def create_appeal_issues(appeal)
      2.times do |idx|
        create(
          :decision_issue,
          :rating,
          decision_review: appeal,
          description: "I am rating decision issue #{idx}"
        )
      end

      2.times do |idx|
        create(
          :decision_issue,
          :nonrating,
          decision_review: appeal,
          description: "I am nonrating decision issue #{idx}"
        )
      end
    end

    def create_motion_to_vacate_mail_task(appeal)
      lit_support_user = User.find_by_css_id("LIT_SUPPORT_USER")
      mail_user = User.find_by_css_id("JOLLY_POSTMAN")
      mail_team_task = create(
        :vacate_motion_mail_task,
        :on_hold,
        appeal: appeal,
        parent: appeal.root_task,
        assigned_by: mail_user
      )
      create(
        :vacate_motion_mail_task,
        :assigned,
        appeal: appeal,
        assigned_to: lit_support_user,
        assigned_by: lit_support_user,
        parent: mail_team_task,
        instructions: ["Initial instructions"]
      )
    end

    def send_mtv_to_judge(appeal, judge, lit_support_user, mail_task, recommendation)
      create(:judge_address_motion_to_vacate_task,
             :assigned,
             appeal: appeal,
             assigned_by: lit_support_user,
             assigned_to: judge,
             assigned_at: Time.zone.now,
             parent: mail_task,
             instructions: "I recommend #{recommendation}.")
    end

    def judge_addresses_mtv(jam_task, disposition, vacate_type, assigned_to)
      params = {
        disposition: disposition,
        vacate_type: vacate_type,
        assigned_to_id: assigned_to&.id,
        instructions: "Instructions from the judge"
      }
      PostDecisionMotionUpdater.new(jam_task, params).process
    end

    def original_fully_dispatched(mtv_judge, drafting_attorney)
      # MTV file numbers with a decided appeal
      # From here a MailTeam user or LitigationSupport team member would create a motion to vacate task
      10.times { create_decided_appeal(mtv_judge, drafting_attorney) }
    end

    def original_at_lit_support(mtv_judge, drafting_attorney)
      # These are ready for the Lit Support user to send_to_judge
      3.times do
        create_decided_appeal(mtv_judge, drafting_attorney).tap do |appeal|
          create_motion_to_vacate_mail_task(appeal)
        end
      end
    end

    def original_at_judge_to_address_motion(mtv_judge, drafting_attorney, lit_support_user)
      MOTION_DISPOSITIONS.each do |disposition|
        # These are ready to be addressed by the Judge
        3.times do
          original_stream = create_decided_appeal(mtv_judge, drafting_attorney)
          mtv_task = create_motion_to_vacate_mail_task(original_stream)
          mtv_task.update!(status: "on_hold")
          send_mtv_to_judge(original_stream, mtv_judge, lit_support_user, mtv_task, disposition)
        end
      end
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def vacate_at_attorney_review(mtv_judge, drafting_attorney, lit_support_user)
      NOT_GRANTED_MOTION_DISPOSITIONS.each do |disposition|
        # These are ready to be reviewed by the decision drafting attorney on the vacate stream
        3.times do
          original_stream = create_decided_appeal(mtv_judge, drafting_attorney)
          mtv_task = create_motion_to_vacate_mail_task(original_stream)
          mtv_task.update!(status: "on_hold")
          jam_task = send_mtv_to_judge(original_stream, mtv_judge, lit_support_user, mtv_task, disposition)
          judge_addresses_mtv(jam_task, disposition, nil, lit_support_user)
        end
      end

      VACATE_TYPES.each do |vacate_type|
        3.times do
          original_stream = create_decided_appeal(mtv_judge, drafting_attorney)
          mtv_task = create_motion_to_vacate_mail_task(original_stream)
          mtv_task.update!(status: "on_hold")
          jam_task = send_mtv_to_judge(original_stream, mtv_judge, lit_support_user, mtv_task, "granted")
          judge_addresses_mtv(jam_task, "granted", vacate_type, drafting_attorney)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/MethodLength
    def fully_processed_vacate_appeal(mtv_judge, drafting_attorney, lit_support_user)
      3.times do
        original_stream = create_decided_appeal(mtv_judge, drafting_attorney)
        mtv_task = create_motion_to_vacate_mail_task(original_stream)
        mtv_task.update!(status: "on_hold")
        jam_task = send_mtv_to_judge(original_stream, mtv_judge, lit_support_user, mtv_task, "granted")
        post_decision_motion = judge_addresses_mtv(jam_task, "granted", "vacate_and_de_novo", drafting_attorney)
        vacate_stream = post_decision_motion.appeal
        jdr_task = vacate_stream.tasks.find_by(type: "JudgeDecisionReviewTask")
        attorney_task = jdr_task.children.find_by(type: "AttorneyTask")
        [jdr_task, attorney_task].each { |t| t.update!(status: "completed") }
        root_task = vacate_stream.tasks.find_by(type: "RootTask")
        BvaDispatchTask.create_from_root_task(root_task)
        dispatch_user = vacate_stream.tasks
          .reload.assigned_to_any_user.find_by(type: "BvaDispatchTask").assigned_to
        last_six = original_stream.veteran.file_number[-6..-1]
        citation_number = "A19#{last_six}"
        outcode_params = {
          citation_number: citation_number,
          decision_date: Time.zone.now,
          redacted_document_location: "\\\\bvacofil1.dva.va.gov\\archdata$\\arch1901\\#{citation_number}.txt",
          file: last_six
        }
        BvaDispatchTask.outcode(vacate_stream.reload, outcode_params, dispatch_user)
      end
    end
    # rubocop:enable Metrics/MethodLength

    def setup_motion_to_vacate_appeals
      lit_support_user = User.find_by(css_id: "LIT_SUPPORT_USER")
      mtv_judge = User.find_by(css_id: "BVAAABSHIRE")
      drafting_attorney = User.find_by(css_id: "BVAEERDMAN")
      u = User.find_by(css_id: "BVAGWHITE")
      BvaDispatch.singleton.add_user(u) unless BvaDispatch.singleton.users.include? u

      original_fully_dispatched(mtv_judge, drafting_attorney)
      original_at_lit_support(mtv_judge, drafting_attorney)
      original_at_judge_to_address_motion(mtv_judge, drafting_attorney, lit_support_user)
      vacate_at_attorney_review(mtv_judge, drafting_attorney, lit_support_user)
      fully_processed_vacate_appeal(mtv_judge, drafting_attorney, lit_support_user)
    end
  end
end
