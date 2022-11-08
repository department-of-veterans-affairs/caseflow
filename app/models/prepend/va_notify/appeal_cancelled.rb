# Module to notify Appellant when Appeal is Cancelled

module AppealCancelled
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Appeal Cancelled"
  # rubocop:enable all

  # Original Method in blahblahblah
  def method_name(params)
    super_return_value = super
  end
end
