# If you are using a Many-to-Many relationship, 
# you may tell amoeba to actually make duplicates 
# of the original related records rather than merely 
# maintaining association with the original records. 
# Cloning is easy, merely tell amoeba which fields to 
# clone in the same way you tell it which fields to include or exclude.

# This example will actually duplicate the warnings and widgets 
# in the database. If there were originally 3 warnings in the database then, 
# upon duplicating a post, you will end up with 6 warnings in the database. 
# This is in contrast to the default behavior where your new post would 
# merely be re-associated with any previously existing warnings and those 
# warnings themselves would not be duplicate.

# Configure your models with one of the styles below and then just run 
# the amoeba_dup method on your model where you would run the dup method normally:
# p = Post.create(:title => "Hello World!", :content => "Lorum ipsum dolor")
# p.comments.create(:content => "I love it!")
# p.comments.create(:content => "This sucks!")
# puts Comment.all.count # should be 2

# my_copy = p.amoeba_dup
# my_copy.save
# By default, when enabled, amoeba will copy any and all associated 
# child records automatically and associate them with the new parent record.
# You can configure the behavior to only include fields that you list or 
# to only include fields that you don't exclude. 
# puts Comment.all.count # should be 4

# This could potential help us Identify where duplicates are located in the database.
# Make a record query

# frozen_string_literal: true

# p = Post.create(:title => "Hello World!", :content => "Lorum ipsum dolor")
# p.comments.create(:content => "I love it!")
# p.comments.create(:content => "This sucks!")
# puts Comment.all.count # should be 2

# my_copy = p.amoeba_dup
# my_copy.save
# By default, when enabled, amoeba will copy any and all associated 

class SplitAppealController < ApplicationController
  include FastJsonapi::ObjectSerializer
   attribute :source_appeal
   attribute :request_issues

  def index
    respond_to do |format|
      format.html { render template: "/appeals/:appeal_id/split/" }
    end
  end

  before_action :validate_cavc_remand_access

  UPDATE_PARAMS = [
    :instructions,
    :judgement_date,
    :mandate_date,
    :remand_appeal_id
  ].freeze

  REMAND_REQUIRED_PARAMS = [
    :source_appeal_id,
    :cavc_decision_type,
    :cavc_docket_number,
    :cavc_judge_full_name,
    :created_by_id,
    :decision_date,
    :decision_issue_ids,
    :instructions,
    :represented_by_attorney,
    :updated_by_id
  ].freeze

  MDR_REQUIRED_PARAMS = [
    :federal_circuit
  ].freeze

  JMR_REQUIRED_PARAMS = [
    :judgement_date,
    :mandate_date
  ].freeze

  PERMITTED_PARAMS = [
    REMAND_REQUIRED_PARAMS,
    JMR_REQUIRED_PARAMS,
    MDR_REQUIRED_PARAMS,
    :remand_subtype,
    :source_form
  ].flatten.freeze

    render json: {
      cavc_remand: WorkQueue::CavcRemandSerializer.new(cavc_remand).serializable_hash[:data][:attributes],
      cavc_appeal: cavc_remand.remand_appeal
    }, status: :ok
  end

  private

  def source_appeal
    @source_appeal ||= Appeal.find_by_uuid(params[:source_appeal_id])
  end

  def cavc_remand
    @cavc_remand ||= CavcRemand.find_by(remand_appeal_id: Appeal.find_by(uuid: params[:appeal_id]).id)
  end

  def validate_cavc_remand_access
    unless CavcLitigationSupport.singleton.user_has_access?(current_user)
      msg = "Only CAVC Litigation Support users can create CAVC Remands"
      fail Caseflow::Error::ActionForbiddenError, message: msg
    end
  end

  def add_cavc_dates_params
    params.require(UPDATE_PARAMS)
    params.permit(PERMITTED_PARAMS).except("remand_appeal_id")
  end

  def creation_params
    params.merge!(created_by_id: current_user.id, updated_by_id: current_user.id, source_appeal_id: source_appeal.id)
    params.require(required_params_by_decisiontype_and_subtype)
    params.permit(PERMITTED_PARAMS).merge(params.permit(decision_issue_ids: []))
  end

  def required_params_by_decisiontype_and_subtype
    case params["cavc_decision_type"]
    when Constants.CAVC_DECISION_TYPES.remand
      case params["remand_subtype"]
      when Constants.CAVC_REMAND_SUBTYPES.mdr
        REMAND_REQUIRED_PARAMS + MDR_REQUIRED_PARAMS
      else
        REMAND_REQUIRED_PARAMS + JMR_REQUIRED_PARAMS
      end
    when Constants.CAVC_DECISION_TYPES.straight_reversal, Constants.CAVC_DECISION_TYPES.death_dismissal
      REMAND_REQUIRED_PARAMS
    end
  end
end

# p = Post.create(:title => "Hello World!", :content => "Lorum ipsum dolor")
# p.comments.create(:content => "I love it!")
# p.comments.create(:content => "This sucks!")
# puts Comment.all.count # should be 2

# my_copy = p.amoeba_dup
# my_copy.save

# a=Appeal.find_by(veteran_file_number: "737469267")
# b=a.amoeba_dup
# puts (b)

# So Here, would the could be this psuedo
# body=source_appeal concat request_issues
# a=body.amoeba_dup
