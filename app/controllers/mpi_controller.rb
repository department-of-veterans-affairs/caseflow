# frozen_string_literal: true

class MpiController < ApplicationController
  def index; end

  def mpi
    @mpi ||= Fakes::MPIService.new
  end

  def search
    results = mpi.search_people_info(
      last_name: params[:last_name],
      first_name: params[:first_name],
      middle_name: params[:middle_name],
      ssn: params[:ssn],
      date_of_birth: params[:date_of_birth],
      gender: params[:gender],
      address: params[:address],
      telephone: params[:telephone]
    )

    binding.pry
    render json: results
  end
end
