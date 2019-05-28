# frozen_string_literal: true

class TaskActionsController < ApplicationController
  before_action :deny_non_bva_admins

  def index
    render(template: "queue/index")
  end

  def deny_non_bva_admins
    redirect_to("/unauthorized") unless Bva.singleton.user_has_access?(current_user)
  end
end
