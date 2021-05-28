# frozen_string_literal: true

##
# Selects the appropriate end product code for a request issue

# The first branch differentiates between primary issues and correction issues
# For corrections, the next branch is correction type
# From there, the next branch is original or remand, then benefit type, then review type, then issue type

class EndProductCodeSelector
  END_PRODUCT_CODES = {
    fiduciary: {
      supplemental_claim: "040SCRFID",
      higher_level_review: "030HLRFID"
    },
    primary: {
      original: {
        compensation: {
          supplemental_claim: {
            rating: "040SCR",
            nonrating: "040SCNR"
          },
          higher_level_review: {
            rating: "030HLRR",
            nonrating: "030HLRNR"
          }
        },
        pension: {
          supplemental_claim: {
            rating: "040SCRPMC",
            nonrating: "040SCNRPMC"
          },
          higher_level_review: {
            rating: "030HLRRPMC",
            nonrating: "030HLRNRPMC"
          }
        }
      },
      remand: {
        duty_to_assist: {
          compensation: {
            appeal: {
              rating: "040BDER",
              nonrating: "040BDENR"
            },
            higher_level_review: {
              rating: "040HDER",
              nonrating: "040HDENR"
            }
          },
          pension: {
            appeal: {
              rating: "040BDERPMC",
              nonrating: "040BDENRPMC"
            },
            higher_level_review: {
              rating: "040HDERPMC",
              nonrating: "040HDENRPMC"
            }
          }
        },
        difference_of_opinion: {
          compensation: {
            higher_level_review: {
              rating: "040AMADOR",
              nonrating: "040AMADONR"
            }
          },
          pension: {
            higher_level_review: {
              rating: "040ADORPMC",
              nonrating: "040ADONRPMC"
            }
          }
        }
      }
    },
    correction: {
      control: {
        original: {
          compensation: {
            supplemental_claim: {
              rating: "930AMASRC",
              nonrating: "930AMASNRC"
            },
            higher_level_review: {
              rating: "930AMAHRC",
              nonrating: "930AMAHNRC"
            }
          },
          pension: {
            supplemental_claim: {
              rating: "930AMASRCPMC",
              nonrating: "930ASNRCPMC"
            },
            higher_level_review: {
              rating: "930AMAHRCPMC",
              nonrating: "930AHNRCPMC"
            }
          }
        },
        remand: {
          duty_to_assist: {
            compensation: {
              appeal: {
                rating: "930AMARRC",
                nonrating: "930AMARNRC"
              },
              higher_level_review: {
                rating: "930AMAHDER",
                nonrating: "930AMAHDENR"
              }
            },
            pension: {
              appeal: {
                rating: "930AMARRCPMC",
                nonrating: "930ARNRCPMC"
              },
              higher_level_review: {
                rating: "930AHDERPMC",
                nonrating: "930AHDENRPMC"
              }
            }
          },
          difference_of_opinion: {
            compensation: {
              higher_level_review: {
                rating: "930AMADOR",
                nonrating: "930AMADONR"
              }
            },
            pension: {
              higher_level_review: {
                rating: "930DORPMC",
                nonrating: "930DONRPMC"
              }
            }
          }
        }
      },
      local_quality_error: {
        original: {
          compensation: {
            supplemental_claim: {
              rating: "930AMASCRLQE",
              nonrating: "930ASCNRLQE"
            },
            higher_level_review: {
              rating: "930AMAHCRLQE",
              nonrating: "930AHCNRLQE"
            }
          },
          pension: {
            supplemental_claim: {
              rating: "930ASCRLQPMC",
              nonrating: "930ASCNRLPMC"
            },
            higher_level_review: {
              rating: "930AHCRLQPMC",
              nonrating: "930AHCNRLPMC"
            }
          }
        },
        remand: {
          duty_to_assist: {
            compensation: {
              appeal: {
                rating: "930AMARRCLQE",
                nonrating: "930ARNRCLQE"
              },
              higher_level_review: {
                rating: "930AMAHDERCL",
                nonrating: "930AMAHDENCL"
              }
            },
            pension: {
              appeal: {
                rating: "930ARRCLQPMC",
                nonrating: "930ARNRCLPMC"
              },
              higher_level_review: {
                rating: "930AHDERLPMC",
                nonrating: "930AHDENLPMC"
              }
            }
          },
          difference_of_opinion: {
            compensation: {
              higher_level_review: {
                rating: "930AMADOR",
                nonrating: "930AMADONR"
              }
            },
            pension: {
              higher_level_review: {
                rating: "930DORPMC",
                nonrating: "930DONRPMC"
              }
            }
          }
        }
      },
      national_quality_error: {
        original: {
          compensation: {
            supplemental_claim: {
              rating: "930AMASCRNQE",
              nonrating: "930ASCNRNQE"
            },
            higher_level_review: {
              rating: "930AMAHCRNQE",
              nonrating: "930AHCNRNQE"
            }
          },
          pension: {
            supplemental_claim: {
              rating: "930ASCRNQPMC",
              nonrating: "930ASCNRNPMC"
            },
            higher_level_review: {
              rating: "930AHCRNQPMC",
              nonrating: "930AHCNRNPMC"
            }
          }
        },
        remand: {
          duty_to_assist: {
            compensation: {
              appeal: {
                rating: "930AMARRCNQE",
                nonrating: "930ARNRCNQE"
              },
              higher_level_review: {
                rating: "930AMAHDERCN",
                nonrating: "930AMAHDENCN"
              }
            },
            pension: {
              appeal: {
                rating: "930ARRCNQPMC",
                nonrating: "930ARNRCNPMC"
              },
              higher_level_review: {
                rating: "930AHDERNPMC",
                nonrating: "930AHDENNPMC"
              }
            }
          },
          difference_of_opinion: {
            compensation: {
              higher_level_review: {
                rating: "930AMADOR",
                nonrating: "930AMADONR"
              }
            },
            pension: {
              higher_level_review: {
                rating: "930DORPMC",
                nonrating: "930DONRPMC"
              }
            }
          }
        }
      }
    }
  }.freeze

  def initialize(request_issue)
    @request_issue = request_issue
  end

  attr_reader :request_issue

  delegate :remanded?, :remand_type, :correction?, :correction_type, :rating?, :nonrating?, :is_unidentified?,
           :decision_review, :decision_review_type, :benefit_type, to: :request_issue

  def call
    return choose_code(initial_ep_code_branch[:remand][remand_type.to_sym]) if remanded?

    choose_code(initial_ep_code_branch[:original])
  end

  private

  def initial_ep_code_branch
    correction? ? END_PRODUCT_CODES[:correction][correction_type.to_sym] : END_PRODUCT_CODES[:primary]
  end

  def issue_type
    nonrating? ? :nonrating : :rating
  end

  def review_type
    type = remanded? ? decision_review.decision_review_remanded.class.name : decision_review_type

    type.underscore.to_sym
  end

  def choose_code(end_product_codes)
    if benefit_type == "fiduciary"
      END_PRODUCT_CODES[:fiduciary][review_type]
    else
      end_product_codes[benefit_type.to_sym][review_type][issue_type]
    end
  end
end
