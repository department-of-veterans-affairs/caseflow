# frozen_string_literal: true

# /inbox is a message queue per-user to manage read/unread messages from Caseflow.
# initial purpose is for reporting async job errors to increase visibility
# but could be used for any kind of messages

class InboxController < ApplicationController
  include PaginationConcern

  before_action :verify_access, :react_routed, :set_application

  def update
    attribute = allowed_params.require(:message_action) + "_at"
    message.update!(attribute.to_sym => Time.zone.now)
    render json: message.to_json
  end

  private

  helper_method :pagination

  def inbox
    @inbox ||= InboxMessages.new(user: current_user, page_size: page_size, page: current_page)
  end

  delegate :messages, to: :inbox
  helper_method :messages

  def message
    @message ||= Message.find(allowed_params.require(:id))
  end

  def total_messages
    @total_messages ||= inbox.total
  end

  alias total_items total_messages

  def allowed_params
    params.permit(:id, :page, :message_action)
  end

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    return true if current_user
  end
end
