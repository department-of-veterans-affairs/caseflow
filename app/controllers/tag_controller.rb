# frozen_string_literal: true

class TagController < ApplicationController
  before_action :verify_access

  def create
    # getting params
    document_id = params[:document_id]

    # finding the document and adding tags
    document = Document.find(document_id)
    errors = []

    tags_request = tag_params[:tags]
    tags_request.each do |tag|
      new_tag = Tag.find_or_create_by(tag)
      begin
        document.tags << new_tag
      rescue ActiveRecord::RecordNotUnique
        errors.push(new_tag.text => "This tag already exists for the document.")
      end
    end

    response_json = { tags: document.tags }
    errors.any? && response_json[:errors] = errors
    render({ json: response_json }, status: :ok)
  end

  def destroy
    document_id = params[:document_id]
    tag_id = params[:id]

    document = Document.find(document_id)

    document.tags.destroy(tag_id)
    render(json: { status: :no_content })
  end

  def auto_tag
    # Runs Scheduled Job with document uuid

    render({ json: response_json }, status: :ok)
  end

  private

  def tag_params
    params.permit(:document_id, tags: [:text])
  end

  def verify_access
    verify_authorized_roles("Reader")
  end

  def find_existing_tag(text)
    Tag.find_by("lower(text) = ?", text.downcase)
  end

  def generate_auto_tags_for_document(doc_uuid, key_phrases = [])
    document = Document.find(doc_uuid)
    key_phrases.each do |key_phrase|
      new_tag = find_existing_tag(key_phrase)
      document.tags << new_tag unless new_tag.nil? || document.tags.includes?(new_tag)
    end
    document.auto_tagged = true
  end
end
