# frozen_string_literal: true

# /inbox is a message queue per-user to manage read/unread messages from Caseflow.
# initial purpose is for reporting async job errors to increase visibility
# but could be used for any kind of messages

class InboxController < ApplicationController
  before_action :verify_access, :react_routed, :set_application

  private

  helper_method :messages, :pagination

  def inbox
    @inbox ||= InboxMessages.new(user: current_user, page_size: page_size, page: current_page) 
  end

  def messages
    @messages ||= inbox.messages
  end

  def message
    @message ||= Message.find(params.require(:message_id))
  end

  def pagination
    {
      page_size: page_size,
      current_page: current_page,
      total_pages: total_pages,
      total_messages: total_messages
    }
  end

  def total_messages
    @total_messages ||= inbox.total
  end

  def total_pages
    total_pages = (total_messages / page_size).to_i
    total_pages += 1 if total_messages % page_size
    total_pages
  end

  def page_size
    50 # TODO: allowed param?
  end

  def current_page
    (allowed_params[:page] || 1).to_i
  end

  def page_start
    return 0 if current_page < 2

    (current_page - 1) * page_size
  end

  def allowed_params
    params.permit(:id, :page)
  end

  def set_application
    RequestStore.store[:application] = "intake" # TODO inbox?
  end

  def verify_access
    return true if current_user

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end
end
