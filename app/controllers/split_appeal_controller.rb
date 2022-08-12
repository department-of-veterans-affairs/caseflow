class SplitAppealController < ApplicationController
  def index
    @splitAppealItem = SplitAppealItem.all 
    render json: @splitAppealItem
end 

def show
    @splitAppealItem = SplitAppealItem.find(params[:id])
    render json: @splitAppealItem
end 

def create
    @splitAppealItem = SplitAppealItem.create(
        split_appeal_reason: params[:split_appeal_reason],
    )
    render json: @splitAppealItem
end 

def update
    @splitAppealItem = SplitAppealItem.find(params[:id])
    @splitAppealItem.update(
        split_appeal_reason: params[:split_appeal_reason],
    )
    render json: @splitAppealItem
end 

def destroy
    @splitAppealItem = SplitAppealItem.all 
    @splitAppealItem = SplitAppealItem.find(params[:id])
    @splitAppealItem.destroy
    render json: @splitAppealItem
end 

end
