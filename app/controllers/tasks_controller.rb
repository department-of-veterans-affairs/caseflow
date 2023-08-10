# frozen_string_literal: true

# Controller that handles requests about tasks.
# Often used by Caseflow Queue.
class TasksController < ApplicationController
  include Errors

  before_action :verify_view_access, only: [:index]
  before_action :verify_task_access, only: [:create]
  skip_before_action :deny_vso_access, only: [:create, :index, :update, :for_appeal]

  # Tasks that are allowed to be created by a user.
  # If a task type is not sent to the frontend via TaskActionRepository's `type` or `options` parameters,
  # then it doesn't need to be included here.
  TASK_CLASSES_LOOKUP = {
    AssessDocumentationTask: AssessDocumentationTask,
    AttorneyDispatchReturnTask: AttorneyDispatchReturnTask,
    AttorneyQualityReviewTask: AttorneyQualityReviewTask,
    AttorneyRewriteTask: AttorneyRewriteTask,
    AttorneyTask: AttorneyTask,
    BlockedSpecialCaseMovementTask: BlockedSpecialCaseMovementTask,
    ChangeHearingDispositionTask: ChangeHearingDispositionTask,
    ColocatedTask: ColocatedTask,
    CavcPoaClarificationTask: CavcPoaClarificationTask,
    CavcRemandProcessedLetterResponseWindowTask: CavcRemandProcessedLetterResponseWindowTask,
    DocketSwitchRulingTask: DocketSwitchRulingTask,
    DocketSwitchDeniedTask: DocketSwitchDeniedTask,
    DocketSwitchGrantedTask: DocketSwitchGrantedTask,
    EducationAssessDocumentationTask: EducationAssessDocumentationTask,
    EducationDocumentSearchTask: EducationDocumentSearchTask,
    FoiaTask: FoiaTask,
    HearingAdminActionTask: HearingAdminActionTask,
    InformalHearingPresentationTask: InformalHearingPresentationTask,
    JudgeAddressMotionToVacateTask: JudgeAddressMotionToVacateTask,
    JudgeAssignTask: JudgeAssignTask,
    JudgeDispatchReturnTask: JudgeDispatchReturnTask,
    JudgeQualityReviewTask: JudgeQualityReviewTask,
    MailTask: MailTask,
    PrivacyActTask: PrivacyActTask,
    PulacCerulloTask: PulacCerulloTask,
    QualityReviewTask: QualityReviewTask,
    ScheduleHearingTask: ScheduleHearingTask,
    SendCavcRemandProcessedLetterTask: SendCavcRemandProcessedLetterTask,
    SpecialCaseMovementTask: SpecialCaseMovementTask,
    Task: Task, # Consider for removal, after cleaning up occurrences in prod
    TranscriptionTask: TranscriptionTask,
    TranslationTask: TranslationTask,
    VhaDocumentSearchTask: VhaDocumentSearchTask,
    SplitAppealTask: SplitAppealTask
  }.freeze

  def set_application
    RequestStore.store[:application] = "queue"
  end

  # e.g, GET /tasks?user_id=xxx&role=colocated
  #      GET /tasks?user_id=xxx&role=attorney
  #      GET /tasks?user_id=xxx&role=judge
  #      GET /tasks?user_id=xxx&role=judge&type=assign
  def index
    tasks = params[:type].eql?("assign") ? QueueForRole.new(user_role).create(user: user).tasks : []
    render json: { tasks: json_tasks(tasks), queue_config: queue_config }
  end

  # To create colocated task
  # e.g, for legacy appeal => POST /tasks,
  # { type: ColocatedTask,
  #   external_id: 123423,
  #   title: "poa_clarification",
  #   instructions: "poa is missing"
  # }
  # for ama appeal = POST /tasks,
  # { type: ColocatedTask,
  #   external_id: "2CE3BEB0-FA7D-4ACA-A8D2-1F7D2BDFB1E7",
  #   title: "something",
  #   parent_id: 2
  #  }
  #
  # To create attorney task
  # e.g, for ama appeal => POST /tasks,
  # { type: AttorneyTask,
  #   external_id: "2CE3BEB0-FA7D-4ACA-A8D2-1F7D2BDFB1E7",
  #   title: "something",
  #   parent_id: 2,
  #   assigned_to_id: 23
  #  }
  def create
    return invalid_type_error unless task_classes_valid?

    tasks = []
    param_groups = create_params.group_by { |param| param[:type] }
    param_groups.each do |task_type, param_group|
      tasks << valid_task_classes[task_type.to_sym].create_many_from_params(param_group, current_user)
    end

    modified_tasks = [parent_tasks_from_params, tasks].flatten.uniq
    render json: { tasks: json_tasks(modified_tasks) }

  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  rescue Caseflow::Error::MailRoutingError => error
    render(error.serialize_response)
  end

  # To update attorney task
  # e.g, for ama/legacy appeal => PATCH /tasks/:id,
  # {
  #   assigned_to_id: 23
  # }
  def update

    Task.transaction do
      tasks = task.update_from_params(update_params, current_user)
      tasks.each { |t| return invalid_record_error(t) unless t.valid? }

      tasks_hash = json_tasks(tasks.uniq)
      if task.appeal.class != LegacyAppeal
        modified_task_contested_claim
      end
      # currently alerts are only returned by ScheduleHearingTask
      # and AssignHearingDispositionTask for virtual hearing related updates
      # Start with any alerts on the current task, then find alerts on the tasks
      # that resulted from the update
      alerts = tasks.reduce(task.alerts) { |acc, t| acc + t.alerts }

      tasks_hash[:alerts] = alerts if alerts # does not add to hash if alerts == []

      render json: { tasks: tasks_hash }
    end
  rescue Caseflow::Error::InvalidEmailError => error
    Raven.capture_exception(error, extra: { application: "hearings" })

    render_update_errors(["message": error.message, "code": error.code])
  rescue ActiveRecord::RecordInvalid => error
    invalid_record_error(error.record)
  rescue AssignHearingDispositionTask::HearingAssociationMissing => error
    Raven.capture_exception(error, extra: { application: "hearings" })

    render_update_errors(["title": "Missing Associated Hearing", "detail": error])
  rescue Caseflow::Error::VirtualHearingConversionFailed => error
    Raven.capture_exception(error, extra: { application: "hearings" })

    render_update_errors(["title": COPY::FAILED_HEARING_UPDATE, "message": error.message, "code": error.code])
  end

  def for_appeal
    no_cache

    tasks = TasksForAppeal.new(appeal: appeal, user: current_user, user_role: user_role).call

    render json: { tasks: json_tasks(tasks)[:data] }
  end

  def reschedule
    if !task.is_a?(NoShowHearingTask)
      fail(Caseflow::Error::ActionForbiddenError, message: COPY::NO_SHOW_HEARING_TASK_RESCHEDULE_FORBIDDEN_ERROR)
    end

    task.reschedule_hearing

    render json: {
      tasks: json_tasks(task.appeal.tasks.includes(*task_includes))[:data]
    }
  end

  def request_hearing_disposition_change
    instructions = create_params&.first&.dig(:instructions)

    change_actions = [
      Constants.TASK_ACTIONS.CREATE_CHANGE_PREVIOUS_HEARING_DISPOSITION_TASK.to_h,
      Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.to_h
    ]

    available_actions = task.available_actions(current_user)

    if available_actions.any? { |action| change_actions.include? action }
      task.create_change_hearing_disposition_task(instructions)
    else
      fail Caseflow::Error::ActionForbiddenError, message: COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR
    end

    render json: {
      tasks: json_tasks(task.appeal.tasks.includes(*task_includes))[:data]
    }
  end

  private

  def send_initial_notification_letter
    # depending on the docket type, create cooresponding task as parent task
    @appeal = task.appeal
    case @appeal.docket_type
    when "evidence_submission"
      parent_task = @appeal.tasks.find_by(type: "EvidenceSubmissionWindowTask")
    when "hearing"
      parent_task = @appeal.tasks.find_by(type: "ScheduleHearingTask")
    when "direct_review"
      parent_task = @appeal.tasks.find_by(type: "DistributionTask")
    end
    unless parent_task.nil?
      @send_initial_notification_letter ||= @appeal.tasks.open.find_by(type: :SendInitialNotificationLetterTask) ||
                                            SendInitialNotificationLetterTask.create!(
                                              appeal: @appeal,
                                              parent: parent_task,
                                              assigned_to: Organization.find_by_url("clerk-of-the-board"),
                                              assigned_by: RequestStore[:current_user]
                                            )
    end
  end

  def send_final_notification_letter
    @send_final_notification_letter ||= task.appeal.tasks.open.find_by(type: :SendFinalNotificationLetterTask) ||
                                        SendFinalNotificationLetterTask.create!(
                                          appeal: task.appeal,
                                          parent: task.parent,
                                          assigned_to: Organization.find_by_url("clerk-of-the-board"),
                                          assigned_by: current_user
                                        )
  end

  def modified_task_contested_claim
    appeal = Appeal.find(task&.appeal&.id)
    if appeal&.contested_claim?
      case task.type
      when "SendInitialNotificationLetterTask"
        process_contested_claim_initial_task
      when "PostSendInitialNotificationLetterHoldingTask"
        process_contested_claim_post_task
      when "SendFinalNotificationLetterTask"
        process_contested_claim_final_task
      else
        "No Task currently available."
      end
    end
  end

  def process_contested_claim_initial_task
    opc = params["select_opc"]
    case opc
    when "task_complete_contested_claim"
      days_on_hold = params["radio_value"].to_i
      instructions = ""
      psi = PostSendInitialNotificationLetterHoldingTask.create!(
        appeal: task.appeal,
        parent: task.parent,
        assigned_to: Organization.find_by_url("clerk-of-the-board"),
        assigned_by: current_user,
        end_date: Time.zone.now + days_on_hold.days
      )
      TimedHoldTask.create_from_parent(psi, days_on_hold: days_on_hold, instructions: instructions)
    when "proceed_final_notification_letter_initial"
      send_final_notification_letter
    end
  end

  def process_contested_claim_post_task
    case task.status
    when "cancelled"
      task.save!
    when "completed"
      if params["select_opc"] == "proceed_final_notification_letter_post_holding"
        send_final_notification_letter
      elsif params["select_opc"] == "resend_initial_notification_letter_post_holding"
        send_initial_notification_letter
      end
    end
  end

  def process_contested_claim_final_task
    case task.status
    when "cancelled"
      if params["select_opc"] == "resend_initial_notification_letter_final"
        send_initial_notification_letter
      end
    when "completed"
      if params["select_opc"] == "resend_final_notification_letter"
        send_final_notification_letter
      elsif params["select_opc"] == "task_complete_contested_claim"
        radio_opc = params["radio_value"].to_i
        if radio_opc == 1
          root_task_id = task.appeal.tasks.find_by(type: "RootTask").id
          params[:parent_id] = root_task_id
          # params[:instructions] = params[:task][:instructions]
          DocketSwitchMailTask.create_from_params(params, current_user)
        end
      end
    end
  end

  def render_update_errors(errors)
    render json: { "errors": errors }, status: :bad_request
  end

  def queue_config
    params[:type].eql?("assign") ? {} : QueueConfig.new(assignee: user).to_hash
  end

  def verify_view_access
    return true if user == current_user ||
                   Judge.new(current_user).attorneys.include?(user) ||
                   current_user.can_act_on_behalf_of_judges?

    fail Caseflow::Error::ActionForbiddenError, message: "Only accessible by members of the Case Movement Team."
  end

  def verify_task_access
    if current_user.vso_employee? && !task_classes.all?(InformalHearingPresentationTask.name.to_sym)
      fail Caseflow::Error::ActionForbiddenError, message: "VSOs cannot create that task."
    end
  end

  def user_role
    params[:role].to_s.empty? ? "generic" : params[:role].downcase
  end

  def user
    @user ||= User.find(params[:user_id])
  end
  helper_method :user

  def task_classes_valid?
    valid_task_class_names = valid_task_classes.keys
    (task_classes - valid_task_class_names).empty?
  end

  def task_classes
    [create_params].flatten.map { |param| param[:type]&.to_sym }.uniq.compact
  end

  def valid_task_classes
    additional_task_classes = Hash[
      *MailTask.subclasses.map { |subclass| [subclass.to_s.to_sym, subclass] }.flatten,
      *HearingAdminActionTask.subclasses.map { |subclass| [subclass.to_s.to_sym, subclass] }.flatten,
      *ColocatedTask.subclasses.map { |subclass| [subclass.to_s.to_sym, subclass] }.flatten
    ]
    TASK_CLASSES_LOOKUP.merge(additional_task_classes)
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def invalid_type_error
    render json: {
      "errors": [
        "title": "Invalid Task Type Error: #{(task_classes - valid_task_classes.keys).join(',')}",
        "detail": "Should be one of the #{TASK_CLASSES_LOOKUP.count} valid types."
      ]
    }, status: :bad_request
  end

  def task
    @task ||= Task.find(params[:id])
  end

  def parent_tasks_from_params
    Task.where(id: create_params.map { |params| params[:parent_id] })
  end

  def create_params
    @create_params ||= [params.require("tasks")].flatten.map do |task|
      appeal = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(task[:external_id])
      task = task.merge(instructions: [task[:instructions]].flatten.compact)
      task = task.permit(:type, { instructions: [] }, :assigned_to_id, :cancellation_reason,
                         :assigned_to_type, :parent_id, business_payloads: [:description, values: {}])
        .merge(assigned_by: current_user)
        .merge(appeal: appeal)

      task = task.merge(assigned_to_type: User.name) if !task[:assigned_to_type]

      if appeal.is_a?(LegacyAppeal)
        if (task[:type] == "BlockedSpecialCaseMovementTask" || task[:type] == "SpecialCaseMovementTask")
          task = task.merge(external_id: params["tasks"][0]["external_id"], legacy_task_type: params["tasks"][0]["legacy_task_type"],
             appeal_type: params["tasks"][0]["appeal_type"])
        end
      end
      task
    end
  end

  def update_params
    params.require("task").permit(
      :status,
      :assigned_to_id,
      :instructions,
      :ihp_path,
      :select_opc,
      :radio_value,
      :parent_id,
      reassign: [:assigned_to_id, :assigned_to_type, :instructions, previous: [:details, :old_judge, :new_judge]],
      business_payloads: [:description, values: {}]
    )
  end

  def json_tasks(tasks, ama_serializer: WorkQueue::TaskSerializer)
    AmaAndLegacyTaskSerializer.create_and_preload_legacy_appeals(
      params: { user: current_user, role: user_role },
      tasks: tasks,
      ama_serializer: ama_serializer
    ).call
  end

  def task_includes
    [
      :appeal,
      :assigned_by,
      :assigned_to,
      :parent
    ]
  end
end
