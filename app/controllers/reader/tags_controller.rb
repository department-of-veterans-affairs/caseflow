class Reader::TagsController < ApplicationController
  def index
    document_id = params[:document_id]
    puts document_id
    document = Document.find(document_id)

    render json: document.tags
  end

  def create
    # getting params
    document_id = params[:document_id]
    tags = request.body.tags

    # finding the document and adding tags
    document = Document.find(document_id)

    Tag.create(tags) do | tag |
      puts "created a tag"
    end
  end
end