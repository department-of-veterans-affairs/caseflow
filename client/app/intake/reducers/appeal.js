import { ACTIONS, FORM_TYPES, REQUEST_STATE } from '../constants';
import { applyCommonReducers, commonStateFromServerIntake } from './common';
import { formatRequestIssues, formatContestableIssues } from '../util/issues';
import {
  convertStringToBoolean,
  getReceiptDateError,
  getBlankOptionError,
  getClaimantError,
  getPageError,
  formatRelationships
} from '../util';
import { update } from '../../util/ReducerUtil';

const updateFromServerIntake = (state, serverIntake) => {
  if (serverIntake.form_type !== FORM_TYPES.APPEAL.key) {
    return state;
  }

  const commonState = commonStateFromServerIntake(serverIntake);

  return update(state, {
    ...commonState,
    docketType: {
      $set: serverIntake.docketType
    }
  });
};

export const mapDataToInitialAppeal = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    addIssuesModalVisible: false,
    nonRatingRequestIssueModalVisible: false,
    unidentifiedIssuesModalVisible: false,
    untimelyExemptionModalVisible: false,
    receiptDate: null,
    receiptDateError: null,
    docketType: null,
    docketTypeError: null,
    veteranIsNotClaimant: null,
    veteranIsNotClaimantError: null,
    claimant: null,
    claimantError: null,
    payeeCode: null,
    claimantName: null,
    claimantRelationship: null,
    claimantType: null,
    powerOfAttorneyName: null,
    legacyOptInApproved: null,
    legacyOptInApprovedError: null,
    legacyAppeals: [],
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
    completeIntakeErrorCode: null,
    completeIntakeErrorData: null,
    veteranValid: null,
    veteranInvalidFields: null,
    requestStatus: {
      submitReview: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

export const appealReducer = (state = mapDataToInitialAppeal(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return mapDataToInitialAppeal();
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(state, action.payload.intake);
  default:
  }

  // The rest of the actions only should be processed if a Appeal intake is being processed
  if (!state.isStarted) {
    return state;
  }

  let veteranIsNotClaimant;

  if (action.payload) {
    veteranIsNotClaimant = action.payload.veteranIsNotClaimant;
  }

  switch (action.type) {
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return mapDataToInitialAppeal();
  case ACTIONS.SET_DOCKET_TYPE:
    return update(state, {
      docketType: {
        $set: action.payload.docketType
      }
    });
  case ACTIONS.SET_RECEIPT_DATE:
    return update(state, {
      receiptDate: {
        $set: action.payload.receiptDate
      }
    });
  case ACTIONS.SET_RECEIPT_DATE_ERROR:
    return update(state, {
      receiptDateError: {
        $set: action.payload.receiptDateError
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
      claimantName: {
        $set: action.payload.claimantName
      },
      claimantType: {
        $set: action.payload.claimantType
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
      docketTypeError: {
        $set: null
      },
      receiptDateError: {
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
      docketTypeError: {
        $set: getBlankOptionError(action.payload.responseErrorCodes, 'docket_type')
      },
      receiptDateError: {
        $set: getReceiptDateError(action.payload.responseErrorCodes, state)
      },
      veteranIsNotClaimantError: {
        $set: getBlankOptionError(action.payload.responseErrorCodes, 'claimant_type')
      },
      claimantError: {
        $set: getClaimantError(action.payload.responseErrorCodes)
      },
      legacyOptInApprovedError: {
        $set: getBlankOptionError(action.payload.responseErrorCodes, 'legacy_opt_in_approved')
      },
      requestStatus: {
        submitReview: {
          $set: REQUEST_STATE.FAILED
        },
        reviewIntakeError: {
          $set: getPageError(action.payload)
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
  case ACTIONS.SET_ISSUE_BENEFIT_TYPE:
    return update(state, {
      nonRatingRequestIssues: {
        [action.payload.issueId]: {
          benefitType: {
            $set: action.payload.benefitType
          }
        }
      }
    });
  default:
    return applyCommonReducers(state, action);
  }
};
