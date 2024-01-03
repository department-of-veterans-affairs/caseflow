# frozen_string_literal: true

class CaseDistributionLeversController < ApplicationController
  before_action :verify_access
  before_action :set_acd_group_organization, only: [:acd_lever_index, :update_levers_and_history]

  def acd_lever_index
    @acd_levers = CaseDistributionLever.all
    history = CaseDistributionAuditLeverEntry.includes(:user, :case_distribution_lever).past_year
    @acd_history = CaseDistributionAuditLeverEntrySerializer.new(history)
      .serializable_hash[:data].map{ |entry| entry[:attributes] }
    @user_is_an_acd_admin = @acd_group_organization.user_is_admin?(current_user)

    render "index"
  end

  def update_levers_and_history
    redirect_to "/unauthorized" unless @acd_group_organization.user_is_admin?(current_user)

    current_levers_list = params["current_levers"].is_a?(Array) ? params["current_levers"].to_json : params["current_levers"]
    errors = update_acd_levers(JSON.parse(current_levers_list))

    if errors.empty?
      audit_lever_entries_list = params["audit_lever_entries"].is_a?(Array) ? params["audit_lever_entries"].to_json : params["audit_lever_entries"]
      errors = add_audit_lever_entries(JSON.parse(audit_lever_entries_list))
      render json: { errors: [], successful: true }
    else
      render json: { errors: errors, successful: false }
    end
  end

  def update_acd_levers(current_levers)
    grouped_levers = current_levers.index_by { |lever| lever["id"] }

    ActiveRecord::Base.transaction do
      @levers = CaseDistributionLever.update(grouped_levers.keys, grouped_levers.values)
      if @levers.all?(&:changed?)
        return []
      else
        return @levers.select(&:invalid?).map { |lever| "Lever ID:#{lever.id} - #{lever.errors.full_messages}" }.join("<br/>")
      end
    end
  end

  def add_audit_lever_entries(audit_lever_entries_data)
    formatted_entries = format_audit_lever_entries(audit_lever_entries_data)

    begin
      ActiveRecord::Base.transaction do
        CaseDistributionAuditLeverEntry.create(formatted_entries)
      end
    rescue StandardError => error
      return [error]
    end

    []
  end

  private

  def verify_access
    return true if current_user&.organizations && current_user&.organizations&.any?(&:users_can_view_levers?)

    Rails.logger.debug("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def set_acd_group_organization
    @acd_group_organization = CDAControlGroup.singleton
  end

  def format_audit_lever_entries(audit_lever_entries_data)
    formatted_audit_lever_entries = []

    begin
      audit_lever_entries_data.each do |entry_data|
        lever = CaseDistributionLever.find_by_title entry_data["lever_title"]

        formatted_audit_lever_entries.push ({
          user: current_user,
          case_distribution_lever: lever,
          user_name: current_user.css_id,
          title: lever.title,
          previous_value: entry_data["original_value"],
          update_value: entry_data["current_value"],
          created_at: entry_data["created_at"]

        })
      end
    rescue Exception => error
      return error
    end

    formatted_audit_lever_entries
  end
end
