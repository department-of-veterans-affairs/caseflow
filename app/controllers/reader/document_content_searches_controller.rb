# frozen_string_literal: true

class Reader::DocumentContentSearchesController < Reader::ApplicationController
  def create
    render json: {
      "matches": [
        {
          "45256": [
            "She sells sea shells",
            "by the sea shore",
          ]
        },
        {
          "68629": [
            "Nobody could catch cold by the sea",
            "nobody wanted appetite by the sea",
            "Sea air was healing, softening, relaxing",
          ]
        },
      ]
    }
  end
end
