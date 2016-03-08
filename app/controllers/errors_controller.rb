class ErrorsController < ApplicationController

  def show
    status_code = params[:status_code]
    puts "errors/#{status_code}"
    render template: "errors/#{status_code}", status: status_code
  end

end