class TagController < ApplicationController
  before_action :verify_access

  def create
    created_tags = []

    # getting params
    document_id = params[:document_id]

    # finding the document and adding tags
    document = Document.find(document_id)
    document.tags.create(tag_params[:tags]) do |tag|
      created_tags << tag
    end
    render({ json: created_tags }, status: :created)
  end

  def destroy
    tag_id = params[:id]
    Tag.destroy(tag_id)
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
