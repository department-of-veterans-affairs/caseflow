# frozen_string_literal: true

class TagController < ApplicationController
  before_action :verify_access
  attr_reader :query_text
  RELATIVE_SCORE_THRESHOLD = 0.5

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
    Document.find(params[:document_id]).update(auto_tagged: true)
    AutotaggedDocumentJob.perform_later(params[:document_id])
    render(json: { status: :ok })
  end

  def correct_spelling
    # @query_text = query_text
    query_text = params[:queryText]
    only_result_text = []
    suggested_spelling = []

    # Array containing the unrefined results
    fuzzy_arr = FuzzyMatch.new(Tag.all, :read => :text).find_all(@query_text)

    # Pushing only the result text into an array
    fuzzy_arr.each do |query_arr|
      only_result_text << query_arr["text"]
    end
    # An array that maps each name to [name, Dice's coefficient, Levenshtein distance] depending on the @query_text
    result_arr = FuzzyMatch.new(only_result_text).find_all_with_score(@query_text)
    # An array that contains only the results above the RELATIVE_SCORE_THRESHOLD
    result_arr.each do |dice|
      if dice[1] >= RELATIVE_SCORE_THRESHOLD
        suggested_spelling << dice[0]
      end
    end
    # suggested_spelling
    render json:{spelling: suggested_spelling}

  end

  private

  def tag_params
    params.permit(tags: [:text])
  end

  def verify_access
    verify_authorized_roles("Reader")
  end
end
