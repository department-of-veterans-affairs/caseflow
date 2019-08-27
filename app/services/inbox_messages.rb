# frozen_string_literal: true

class InboxMessages
  def initialize(user:, page_size: 50, page: 1)
    @user = user
    @page_size = page_size
    @page = page
  end

  def total
    user.messages.count
  end

  def messages
    user.messages.order(read_at: :desc, created_at: :desc).page(page).per(page_size)
  end

  private

  attr_reader :user, :page_size, :page
end
