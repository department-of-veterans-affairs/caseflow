# frozen_string_literal: true

FactoryBot.define do
  factory :issref, class: VACOLS::Issref do
    prog_code { nil }
    prog_desc { nil }
    iss_code { nil }
    iss_desc { nil }
    lev1_code { nil }
    lev1_desc { nil }
    lev2_code { nil }
    lev2_desc { nil }
    lev3_code { nil }
    lev3_desc { nil }
  end
end
