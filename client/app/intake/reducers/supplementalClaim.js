import { ACTIONS, FORM_TYPES, REQUEST_STATE } from '../constants';
import { applyCommonReducers, commonStateFromServerIntake } from './common';
import { formatRequestIssues, formatContestableIssues } from '../util/issues';
import {
  convertStringToBoolean,
  getReceiptDateError,
  getBlankOptionError,
  getClaimantError,
  getPageError,
  formatRelationships,
  getDefaultPayeeCode
} from '../util';
import { update } from '../../util/ReducerUtil';

const updateFromServerIntake = (state, serverIntake) => {
  if (serverIntake.form_type !== FORM_TYPES.SUPPLEMENTAL_CLAIM.key) {
    return state;
  }

  const commonState = commonStateFromServerIntake(serverIntake);
  return update(state, {
    ...commonState,
    benefitType: {
      $set: serverIntake.benefit_type
    }
  });
};

export const mapDataToInitialSupplementalClaim = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    addIssuesModalVisible: false,
    nonRatingRequestIssueModalVisible: false,
    unidentifiedIssuesModalVisible: false,
    untimelyExemptionModalVisible: false,
    legacyOptInModalVisible: false,
    removeIssueModalVisible: false,
    receiptDate: null,
    receiptDateError: null,
    benefitType: null,
    benefitTypeError: null,
    veteranIsNotClaimant: null,
    veteranIsNotClaimantError: null,
    claimant: null,
    claimantError: null,
    payeeCode: null,
    payeeCodeError: null,
    legacyOptInApproved: null,
    legacyOptInApprovedError: null,
    legacyAppeals: [],
    veteranValid: null,
    veteranInvalidFields: null,
    isStarted: false,
    isReviewed: false,
    isComplete: false,
    issueCount: 0,
    intakeUser: null,
    processedAt: null,
    asyncJobUrl: null,
    nonRatingRequestIssues: { },
    contestableIssues: { },
    reviewIntakeError: null,
    errorUUID: null,
    completeIntakeErrorCode: null,
    completeIntakeErrorData: null,
    redirectTo: null,
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

export const supplementalClaimReducer = (state = mapDataToInitialSupplementalClaim(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialSupplementalClaim();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
  default:
  }

  // The rest of the actions only should be processed if a SupplementalClaim intake is being processed
  if (!state.isStarted) {
    return state;
  }

  let veteranIsNotClaimant;

  if (action.payload) {
    veteranIsNotClaimant = convertStringToBoolean(action.payload.veteranIsNotClaimant);
  }

  switch (action.type) {
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return mapDataToInitialSupplementalClaim();
  case ACTIONS.SET_RECEIPT_DATE:
    return update(state, {
      receiptDate: {
        $set: action.payload.receiptDate
      }
    });
  case ACTIONS.SET_BENEFIT_TYPE:
    return update(state, {
      benefitType: {
        $set: action.payload.benefitType
      }
    });
  case ACTIONS.SET_VETERAN_IS_NOT_CLAIMANT:
    return update(state, {
      veteranIsNotClaimant: {
        $set: veteranIsNotClaimant
      },
      claimant: {
        $set: veteranIsNotClaimant === true ? state.claimant : null
      }
    });
  case ACTIONS.SET_CLAIMANT:
    return update(state, {
      claimant: {
        $set: action.payload.claimant
      },
      payeeCode: {
        $set: getDefaultPayeeCode(state, action.payload.claimant)
      }
    });
  case ACTIONS.SET_PAYEE_CODE:
    return update(state, {
      payeeCode: {
        $set: action.payload.payeeCode
      }
    });
  case ACTIONS.SET_LEGACY_OPT_IN_APPROVED:
    return update(state, {
      legacyOptInApproved: {
        $set: action.payload.legacyOptInApproved
      }
    });
  case ACTIONS.SUBMIT_REVIEW_START:
    return update(state, {
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.SUBMIT_REVIEW_SUCCEED:
    return updateFromServerIntake(update(state, {
      receiptDateError: {
        $set: null
      },
      benefitTypeError: {
        $set: null
      },
      legacyOptInApprovedError: {
        $set: null
      },
      veteranIsNotClaimantError: {
        $set: null
      },
      claimantError: {
        $set: null
      },
      payeeCodeError: {
        $set: null
      },
      isReviewed: {
        $set: true
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    }), action.payload.intake);
  case ACTIONS.SUBMIT_REVIEW_FAIL:
    return update(state, {
      receiptDateError: {
        $set: getReceiptDateError(action.payload.responseErrorCodes, state)
      },
      benefitTypeError: {
        $set: getBlankOptionError(action.payload.responseErrorCodes, 'benefit_type')
      },
      legacyOptInApprovedError: {
        $set: getBlankOptionError(action.payload.responseErrorCodes, 'legacy_opt_in_approved')
      },
      veteranIsNotClaimantError: {
        $set: getBlankOptionError(action.payload.responseErrorCodes, 'veteran_is_not_claimant')
      },
      claimantError: {
        $set: getClaimantError(action.payload.responseErrorCodes)
      },
      payeeCodeError: {
        $set: getBlankOptionError(action.payload.responseErrorCodes, 'payee_code')
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        },
        reviewIntakeError: {
          $set: getPageError(action.payload.responseErrorCodes)
        },
        errorUUID: {
          $set: action.payload.errorUUID
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_START:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.COMPLETE_INTAKE_SUCCEED:
    return updateFromServerIntake(update(state, {
      redirectTo: {
        $set: action.payload.intake.serverIntake ? action.payload.intake.serverIntake.redirect_to : null
      },
      isComplete: {
        $set: true
      },
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    }), action.payload.intake);
  case ACTIONS.COMPLETE_INTAKE_FAIL:
    return update(state, {
      requestStatus: {
        completeIntake: {
          $set: REQUEST_STATE.FAILED
        },
        completeIntakeErrorCode: {
          $set: action.payload.responseErrorCode
        },
        completeIntakeErrorData: {
          $set: action.payload.responseErrorData
        }
      }
    });
  case ACTIONS.SET_ISSUE_SELECTED:
    return update(state, {
      ratings: {
        [action.payload.approxDecisionDate]: {
          issues: {
            [action.payload.issueId]: {
              isSelected: {
                $set: action.payload.isSelected
              }
            }
          }
        }
      },
      issueCount: {
        $set: action.payload.isSelected ? state.issueCount + 1 : state.issueCount - 1
      }
    });
  case ACTIONS.NEW_NONRATING_REQUEST_ISSUE:
    return update(state, {
      nonRatingRequestIssues: {
        [Object.keys(state.nonRatingRequestIssues).length]: {
          $set: {
            category: null,
            description: null,
            decisionDate: null
          }
        }
      }
    });
  case ACTIONS.SET_ISSUE_CATEGORY:
    return update(state, {
      nonRatingRequestIssues: {
        [action.payload.issueId]: {
          category: {
            $set: action.payload.category
          }
        }
      }
    });
  case ACTIONS.SET_ISSUE_DESCRIPTION:
    return update(state, {
      nonRatingRequestIssues: {
        [action.payload.issueId]: {
          description: {
            $set: action.payload.description
          }
        }
      }
    });
  case ACTIONS.SET_ISSUE_DECISION_DATE:
    return update(state, {
      nonRatingRequestIssues: {
        [action.payload.issueId]: {
          decisionDate: {
            $set: action.payload.decisionDate
          }
        }
      }
    });
  default:
    return applyCommonReducers(state, action);
  }
};
