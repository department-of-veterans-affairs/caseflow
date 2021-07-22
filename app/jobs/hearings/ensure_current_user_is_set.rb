# frozen_string_literal: true

module Hearings::EnsureCurrentUserIsSet
  def ensure_current_user_is_set
    RequestStore.store[:current_user] ||= User.system_user
  end
end
