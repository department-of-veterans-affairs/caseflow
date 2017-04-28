class TagController < ApplicationController
  before_action :verify_access

  def create
    # getting params
    document_id = params[:document_id]

    # finding the document and adding tags
    document = Document.find(document_id)

    tags_request = tag_params[:tags]
    tags_request.each do |tag|
      new_tag = Tag.find_or_create_by(tag)
      document.tags << new_tag
    end

    render({ json: document.tags }, status: :created)
  end

  def destroy
    document_id = params[:document_id]
    tag_id = params[:id]

    document = Document.find(document_id)

    document.tags.delete(tag_id)
    render(json: { status: :no_content })
  end

  private

  def tag_params
    params.permit(tags: [:text])
  end

  def verify_access
    verify_authorized_roles("Reader")
  end
end
