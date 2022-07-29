# frozen_string_literal: true

#Module containing Aspect Overrides to Classes used to Track Statuses for Appellant Notification
module AppellantNotification

    class AppealDocketed
        def notify_appellant(appeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.appeal_docketed)
            #Shoryuken::Client.queues('default').send_message(message_body: {
    queue_url: "<queue_url>", 	
    message_body: "Updated participant ID list 7/19/2022",
    message_attributes: {
        "claimant" => {
        value: "<insert participant_id here>",
        data_type: "String"
        },
        "template_id" => {
        value: “<insert template_id here>”,
        data_type: "String"
        },
        “appeal_id” => {
        value: <insert appeal_id here>,
        data_type: “Integer”
        },
        “appeal_type” => {
        value: “<insert appeal_type here>”,
        data_type: “String”
        },
        “status” => {
        value: “<insert status here>”,
        data_type: “String”
    }
}
)
        end

        def distribution_task
            @distribution_task ||= @appeal.tasks.open.find_by(type: :DistributionTask) 
            || (DistributionTask.create!(appeal: @appeal, parent: @root_task) 
            && notify_appellant(appeal_id, participant_id, type, template_id))
        end

        def docket_appeal    
          super    
          notify_appellant(appeal_id, participant_id, type, template_id)
        end
    end

    class AppealDecisionMailed
        def notify_appellant(appeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.appeal_decision_mailed)
            ***CODE GOES HERE***
        end

        #Aspect for Legacy Appeals
        def complete_root_task!    
            super    
            notify_appellant(appeal_id, participant_id, type, template_id)
        end

        #Aspect for AMA Appeals
        def complete_dispatch_root_task!    
            super    
            notify_appellant(appeal_id, participant_id, type, template_id)
        end
    end

    class HearingScheduled
        def notify_appellant(appeal_id, participant_id, type, template_idappeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.hearing_scheduled)
            ***CODE GOES HERE***
        end

        def create_hearing(task_values)    
            super    
            notify_appellant(appeal_id, participant_id, type, template_id)
        end
    end

    class HearingPostponed
        def notify_appellant(appeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.hearing_postponed)
            ***CODE GOES HERE***
        end
        
        def postpone!    
            super    
            notify_appellant(appeal_id, participant_id, type, template_id)
        end

        def mark_hearing_with_disposition(payload_values:, instructions: nil)    
            multi_transaction do      
                if payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error        
                    update_hearing_disposition_and_notes(payload_values)      
                elsif payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed        
                    update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)        
                    notify_appellant(participant_id, template_id)      
                end      
                clean_up_virtual_hearing      
                reschedule_or_schedule_later(        
                    instructions: instructions,        
                    after_disposition_update: payload_values[:after_disposition_update]      
                    )    
            end  
        end
    end

    class HearingWithdrawn
        def notify_appellant(appeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.hearing_withdrawn)
            ***CODE GOES HERE***
        end
        
        def cancel!    
            super    
            notify_appellant(appeal_id, participant_id, type, template_id)
        end
    end

    class IHPTaskPending
        def notify_appellant(appeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.ihp_task_pending)
            ***CODE GOES HERE***
        end

        def create_ihp_tasks!
            appeal = @parent.appeal
            appeal.representatives.select { |org| org.should_write_ihp?(appeal) }.map do |vso_organization|
              # For some RAMP appeals, this method may run twice.
              existing_task = InformalHearingPresentationTask.find_by(
                appeal: appeal,
                assigned_to: vso_organization
              )
              existing_task || InformalHearingPresentationTask.create!(
                appeal: appeal,
                parent: @parent,
                assigned_to: vso_organization
              )
              notify_appellant(appeal_id, participant_id, type, template_id)
            end
        end
    end

    class IHPTaskComplete
        def notify_appellant(appeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.ihp_task_complete)
            ***CODE GOES HERE***
        end

        def update_status_if_children_tasks_are_closed(child_task)
            if children.any? && children.open.empty? && on_hold?
              if assigned_to.is_a?(Organization) && cascade_closure_from_child_task?(child_task)
                return all_children_cancelled_or_completed
              end
              if ["RootTask", "DistributionTask", "AttorneyTask"].include?(child_task.parent.type) && 
                (child_task.type.include?("InformalHearingPresentationTask") || 
                child_task.type.include?("IhpColocatedTask"))
                notify_appellant(appeal_id, participant_id, type, template_id)
              end
              update_task_if_children_tasks_are_completed
            end
        end
    end

    class PrivacyActPending
        def notify_appellant(appeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.privacy_act_pending)
            ***CODE GOES HERE***
        end

        def create_privacy_act_task
            super
            def notify_appellant(appeal_id, participant_id, type, template_id)        
        end
    end

    class PrivacyActComplete
        def notify_appellant(appeal_id, participant_id, type, template_id = Constants.TEMPLATE_IDS.privacy_act_complete)
            ***CODE GOES HERE***
        end

        def cascade_closure_from_child_task?(child_task)  
            if (child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask))
                notify_appellant(appeal_id, participant_id, type, template_id)  
            end  
            child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask)
        end
    end
end