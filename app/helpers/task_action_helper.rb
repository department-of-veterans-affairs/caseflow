# frozen_string_literal: true

module TaskActionHelper
  def build_hash(config, task, user)
    if config[:func]
      data = TaskActionRepository.send(config[:func], task, user)

      if data&.delete(:returns_complete_hash)
        data
      else
        config.merge(data: data)
      end
    else
      config
    end
  end
end
