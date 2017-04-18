class Reader::TagsController < ApplicationController
  #before_action :verify_system_admin

  def index
    document_id = params[:document_id]
    document = Document.find(document_id)

    render json: document.tags
  end

  def create
    created_tags = []

    # getting params
    document_id = params[:document_id]
    tags = tag_params

    # finding the document and adding tags
    document = Document.find(document_id)
    
    document.tags.create(tags[:tags]) do | tag |
      created_tags << tag
    end
    render(:json => { :tags => created_tags }, :status => :created)
  end

  def destroy
    tag_id = params[:id]
    Document.delete(tag_id)
    render(:json => 'no_content', :status => :no_content)
  end

  private
  def tag_params
    params.permit(tags: [:text])
  end
end