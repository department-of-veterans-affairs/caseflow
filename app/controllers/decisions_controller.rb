require 'htmltoword'

class DecisionsController < ApplicationController
  def index
  end

  def docx
    issues = decision_document_params
    
    my_html = '<html><head></head><body>'
    issues.keys.map do |key|
      my_html = "#{my_html}<h1>#{issues[key]["type"]}</h1><h2>#{issues[key]["subType"]}</h2><p>#{issues[key]["rating"]}</p>"
    end
    file_path = 'tmp/test.docx'
    my_html = my_html + '</body></html>'
    document = Htmltoword::Document.create(my_html)
    file = Htmltoword::Document.create_and_save(my_html, file_path)

    render json: {}
  end

  def download
    file_path = 'tmp/test.docx'
    send_file(file_path, type: "application/docx")
  end

  def logo_name
    "Decision"
  end

  def decision_document_params
    params.require(:issueList)
  end
end
