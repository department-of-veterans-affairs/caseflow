class SchedulePeriodsController < ApplicationController
  def index
    respond_to do |format|
      format.json { render json: { schedule_periods: [
          {
              startDate: '10/01/2018',
              endDate: '03/31/2019',
              type: 'Judge',
              createdAt: '07/03/2018',
              user: 'Justin Madigan',
              fileName: 'fake file name'
          },
          {
              startDate: '10/01/2018',
              endDate: '03/31/2019',
              type: 'RO/CO',
              createdAt: '07/03/2018',
              user: 'Justin Madigan',
              fileName: 'fake file name'
          }
      ] } }
    end
  end
end
