# frozen_string_literal: true

class InboxMessages
  VISIBLE_DURATION = 120.days

  def initialize(user:, page_size: 50, page: 1, created_after: VISIBLE_DURATION.ago)
    @user = user
    @page_size = page_size
    @page = page
    @created_after = created_after
  end

  def total
    user.messages.created_after(created_after).count
  end

  def messages
    user.messages.created_after(created_after).order(read_at: :desc, created_at: :desc).page(page).per(page_size)
  end

  private

  attr_reader :user, :page_size, :page, :created_after
end
