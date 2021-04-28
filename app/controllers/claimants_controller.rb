# frozen_string_literal: true

class ClaimantsController < ApplicationController
  def refresh_claimant_poa
    poa = BgsPowerOfAttorney.find_or_create_by_claimant_participant_id(params[:participant_id])
    poa&.update_cached_attributes!
    render json: { poa: poa }
  end
end
