class SendNotificationJob < CaseflowJob
  queue_as :send_notifications
  application_attr :hearing_schedule

  def perform(notification)
    RequestStore.store[:current_user] = User.system_user
    
   response = VANotifyService.send_notifications(notification[:email_address],notification[:email_template_id], nil,nil)
   puts response
  end
end