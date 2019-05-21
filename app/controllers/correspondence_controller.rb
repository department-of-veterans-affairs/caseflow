# frozen_string_literal: true

class CorrespondenceController < ApplicationController

  def example
    task = Task.find(params[:id])

    document = ::Caracal::Document.new
    document.h1('Example document')
    document.p(format("Appeal for Veteran %s requires additional attention.", task.appeal.veteran_full_name))

    send_data(
      document.render.string,
      filename: "attention_needed.docx"
    )
  end  
end