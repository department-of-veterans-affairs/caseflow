class Idt::Api::V1::AppealsController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :validate_token

  def file_number
    request.headers["FILE"]
  end

  def token
    request.headers["TOKEN"]
  end

  def css_id
    Idt::Token.associated_css_id(token)
  end

  def validate_token
    return render json: { message: "Missing token" }, status: 400 unless token
    return render json: { message: "Invalid token" }, status: 403 unless Idt::Token.active?(token)
  end

  def index
    user = User.find_by(css_id: css_id)
    return render json: { message: "User must be attorney" }, status: 403 unless user.attorney_in_vacols?
    appeals = file_number ? appeals_by_file_number : appeals_assigned_to_user(user)

    render json: json_appeals(appeals)
  end

  def appeals_assigned_to_user(user)
    # TODO: add AMA appeals
    LegacyWorkQueue.tasks_with_appeals(user, "attorney")[1].select(&:active?)
  end

  def appeals_by_file_number
    # TODO: add AMA appeals
    LegacyAppeal.fetch_appeals_by_file_number(file_number).select(&:active?)
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::Idt::V1::AppealSerializer
    ).as_json
  end
end
