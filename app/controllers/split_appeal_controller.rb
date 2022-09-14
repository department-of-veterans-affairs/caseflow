# frozen_string_literal: true

class SplitAppealController < ApplicationController
  protect_from_forgery with: :exception

  def split_appeal
    params

    render json: { message: "Success" }

    # render json: { message: params.errors[0] }, status: :bad_request

    # get appeal from params
    appeal = Appeal.find(params[:appeal_id])

    # duplicate appeal
    dup_appeal = appeal.amoeba_dup

    # save the duplicate 
    dup_appeal.save

    # update the child task tree with parent, passing CSS ID of user for validation
    dup_appeal.clone_task_tree(appeal, user_css_id)

    # clone the hearings and hearing relations from parent appeal
    dup_appeal.clone_hearings(appeal)
  end
end
