module CorrespondenceControllerUtil

  def current_correspondence
    @current_correspondence ||= correspondence
  end

  def pdf
    # Hard-coding Document access until CorrespondenceDocuments are uploaded to S3Bucket
    document = Document.limit(200)[params[:pdf_id].to_i]

    document_disposition = "inline"
    if params[:download]
      document_disposition = "attachment; filename='#{params[:type]}-#{params[:id]}.pdf'"
    end

    # The line below enables document caching for a month.
    expires_in 30.days, public: true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: document_disposition
    )
  end

  def set_handle_mail_superuser_or_supervisor_params(current_user, params)
    @mail_team_users = User.mail_team_users.pluck(:css_id)
    @is_superuser = current_user.mail_superuser?
    @is_supervisor = current_user.mail_supervisor?
    @reassign_remove_task_id = params[:taskId].strip if params[:taskId].present?
    @action_type = params[:userAction].strip if params[:userAction].present?
  end

  def correspondence_team
    if current_user.mail_superuser? || current_user.mail_supervisor?
      handle_mail_superuser_or_supervisor
    elsif current_user.mail_team_user?
      redirect_to "/queue/correspondence"
    else
      redirect_to "/unauthorized"
    end
  end


end
