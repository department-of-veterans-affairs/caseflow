class Hearings::SchedulePeriodsController < HearingScheduleController
  def index
    respond_to do |format|
      format.html { render "hearing_schedule/index" }
      format.json { render json: { schedule_periods: SchedulePeriod.all.map(&:to_hash) } }
    end
  end

  # rubocop:disable Metrics/MethodLength
  def show
    # TODO: remove sleep, rubocop disable, and faked data when we actually run the algorithm!
    sleep(2)
    render json: { schedule_period: SchedulePeriod.find(params[:schedule_period_id]).to_hash.merge(
      hearing_days: [
        {
          hearing_date: "2018-06-04",
          hearing_type: "Video",
          regional_office: "St. Petersburg, FL",
          room: "1",
          judge: "Sarah Smith"
        },
        {
          hearing_date: "2018-06-04",
          hearing_type: "Video",
          regional_office: "Baltimore, MD",
          room: "1",
          judge: "Sarah Smith"
        },
        {
          hearing_date: "2018-06-04",
          hearing_type: "Video",
          regional_office: "Portland, OR",
          room: "1",
          judge: "Sarah Smith"
        }
      ]
    ) }
  end
  # rubocop:enable Metrics/MethodLength

  def create
    file_name = params["type"] + Time.now.to_s + '.xlsx'
    file = base64_to_file(params["file"], file_name)
    S3Service.store_file(file_name, file.tempfile.to_path.to_s, :filepath)
    schedule_period = SchedulePeriod.create!(schedule_period_params.merge(user_id: current_user.id, file_name: file_name))
    render json: { id: schedule_period.id }
  end

  def schedule_period_params
    params.require(:schedule_period).permit(:type, :file, :start_date, :end_date)
  end

  def base64_to_file(base64_data, filename=nil)
    return base64_data unless base64_data.is_a? String

    start_regex = /[a-z]{3,4};base64,/
    filename ||= SecureRandom.hex

    regex_result = start_regex.match(base64_data)
    if base64_data && regex_result
      start = regex_result.to_s
      tempfile = Tempfile.new(filename)
      tempfile.binmode
      tempfile.write(Base64.decode64(base64_data[start.length..-1]))
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
          :tempfile => tempfile,
          :filename => filename,
          :original_filename => filename
      )
      uploaded_file
    else
      nil
    end
  end
end
