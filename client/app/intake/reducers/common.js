// shared functions between reducers
import { ACTIONS } from '../constants';
import { formatRelationships } from '../util';
import { formatRequestIssues, formatContestableIssues } from '../util/issues';
import { formatIssueModificationRequests } from '../util/issueModificationRequests';

import { update } from '../../util/ReducerUtil';

export const commonReducers = (state, action) => {
  let actionsMap = {};
  let listOfIssues = state.addedIssues ? state.addedIssues : [];
  const pendingIssueModificationRequests = state.pendingIssueModificationRequests || [];

  actionsMap[ACTIONS.TOGGLE_ADD_DECISION_DATE_MODAL] = () => {
    return update(state, {
      $toggle: ['addDecisionDateModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_ADDING_ISSUE] = () => {
    return update(state, {
      $toggle: ['addingIssue']
    });
  };

  actionsMap[ACTIONS.TOGGLE_ADD_ISSUES_MODAL] = () => {
    return update(state, {
      $toggle: ['addIssuesModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_NONRATING_REQUEST_ISSUE_MODAL] = () => {
    return update(state, {
      $toggle: ['nonRatingRequestIssueModalVisible'],
      addIssuesModalVisible: {
        $set: false
      }
    });
  };

  actionsMap[ACTIONS.TOGGLE_LEGACY_OPT_IN_MODAL] = () => {
    return update(state, {
      $toggle: ['legacyOptInModalVisible'],
      addIssuesModalVisible: {
        $set: false
      },
      nonRatingRequestIssueModalVisible: {
        $set: false
      },
      currentIssueAndNotes: {
        $set: action.payload.currentIssueAndNotes
      }
    });
  };

  actionsMap[ACTIONS.TOGGLE_ISSUE_REMOVE_MODAL] = () => {
    return update(state, {
      $toggle: ['removeIssueModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_EDIT_INTAKE_ISSUES_MODAL] = () => {
    return update(state, {
      $toggle: ['editIntakeIssueModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_REQUEST_ISSUE_MODIFICATION_MODAL] = () => {
    return update(state, {
      $toggle: ['requestIssueModificationModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_REQUEST_ISSUE_REMOVAL_MODAL] = () => {
    return update(state, {
      $toggle: ['requestIssueRemovalModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_REQUEST_ISSUE_WITHDRAWAL_MODAL] = () => {
    return update(state, {
      $toggle: ['requestIssueWithdrawalModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_REQUEST_ISSUE_ADDITION_MODAL] = () => {
    return update(state, {
      $toggle: ['requestIssueAdditionModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_CANCEL_PENDING_REQUEST_ISSUE_MODAL] = () => {
    return update(state, {
      $toggle: ['cancelPendingRequestIssueModalVisible']
    });
  };

  actionsMap[ACTIONS.TOGGLE_CONFIRM_PENDING_REQUEST_ISSUE_MODAL] = () => {
    return update(state, {
      $toggle: ['confirmPendingRequestIssueModalVisible']
    });
  };

  actionsMap[ACTIONS.ACTIVE_ISSUE_MODIFICATION_REQUEST] = () => {
    return update(state, {
      activeIssueModificationRequest: {
        $set: action.payload.data
      }
    });
  };

  actionsMap[ACTIONS.SET_MST_PACT_DETAILS] = () => {
    const { editIssuesDetails } = action.payload;
    const index = editIssuesDetails.issueProps.issueIndex;

    listOfIssues[index].mstChecked = editIssuesDetails.issueProps.mstChecked;
    listOfIssues[index].pactChecked = editIssuesDetails.issueProps.pactChecked;
    listOfIssues[index].mstJustification = editIssuesDetails.issueProps.mstJustification;
    listOfIssues[index].pactJustification = editIssuesDetails.issueProps.pactJustification;

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.TOGGLE_CORRECTION_TYPE_MODAL] = () => {
    return update(state, {
      $toggle: ['correctIssueModalVisible'],
      activeIssue: {
        $set: action.payload.index
      },
      isNewIssue: {
        $set: action.payload.isNewIssue
      }
    });
  };

  actionsMap[ACTIONS.TOGGLE_UNIDENTIFIED_ISSUES_MODAL] = () => {
    return update(state, {
      $toggle: ['unidentifiedIssuesModalVisible'],
      nonRatingRequestIssueModalVisible: {
        $set: false
      }
    });
  };

  actionsMap[ACTIONS.TOGGLE_UNTIMELY_EXEMPTION_MODAL] = () => {
    return update(state, {
      $toggle: ['untimelyExemptionModalVisible'],
      addIssuesModalVisible: {
        $set: false
      },
      nonRatingRequestIssueModalVisible: {
        $set: false
      },
      legacyOptInModalVisible: {
        $set: false
      },
      currentIssueAndNotes: {
        $set: action.payload.currentIssueAndNotes
      }
    });
  };

  actionsMap[ACTIONS.ADD_DECISION_DATE] = () => {
    const { decisionDate, index } = action.payload;

    listOfIssues[index].decisionDate = decisionDate;
    listOfIssues[index].editedDecisionDate = decisionDate;

    return {
      ...state,
      editedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.ADD_ISSUE] = () => {
    let addedIssues = [...listOfIssues, action.payload];

    return {
      ...state,
      addedIssues,
      issueCount: addedIssues.length
    };
  };

  actionsMap[ACTIONS.REMOVE_ISSUE] = () => {
    // issues are removed by position, because not all issues have referenceIds
    listOfIssues.splice(action.payload.index, 1);

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.WITHDRAW_ISSUE] = () => {
    listOfIssues[action.payload.index].withdrawalPending = true;

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.MOVE_TO_PENDING_REVIEW] = () => {
    return {
      ...state,
      addedIssues: listOfIssues,
      pendingIssueModificationRequests: [...pendingIssueModificationRequests, action.payload.issueModificationRequest]
    };
  };

  actionsMap[ACTIONS.ADD_TO_PENDING_REVIEW] = () => {
    return {
      ...state,
      pendingIssueModificationRequests: [...pendingIssueModificationRequests, action.payload.issueModificationRequest]
    };
  };

  actionsMap[ACTIONS.REMOVE_FROM_PENDING_REVIEW] = () => {
    if (action.payload.issueModificationRequest === null) {
      pendingIssueModificationRequests.splice(action.payload.index, 1);

      return {
        ...state,
        pendingIssueModificationRequests
      };
    }

    return {
      ...state,
      pendingIssueModificationRequests: pendingIssueModificationRequests.find(
        (issue) => (issue.identifier !== action.payload.issueModificationRequest.identifier))
    };
  };

  actionsMap[ACTIONS.CANCEL_OR_REMOVE_PENDING_REVIEW] = () => {
    let updatedPendingModificationRequests;

    if (action.payload.issueModificationRequest.id) {
      updatedPendingModificationRequests = pendingIssueModificationRequests.map((issue) =>
        issue.id === action.payload.issueModificationRequest.id ?
          { ...issue, status: 'cancelled' } :
          issue
      );
    } else {
      // There is no ID so it's a brand new issue modfication request so it can just be removed
      updatedPendingModificationRequests = pendingIssueModificationRequests.filter(
        (issueRequest) => issueRequest.identifier !== action.payload.issueModificationRequest.identifier
      );
    }

    return {
      ...state,
      pendingIssueModificationRequests: updatedPendingModificationRequests
    };
  };

  actionsMap[ACTIONS.UPDATE_PENDING_REVIEW] = () => {
    const index = pendingIssueModificationRequests.findIndex((issue) => issue.identifier === action.payload.identifier);

    return update(state, {
      pendingIssueModificationRequests: {
        [index]: {
          $merge: action.payload.data
        }
      }
    });
  };

  actionsMap[ACTIONS.SET_ISSUE_WITHDRAWAL_DATE] = () => {
    return {
      ...state,
      withdrawalDate: action.payload.withdrawalDate
    };
  };

  actionsMap[ACTIONS.CORRECT_ISSUE] = () => {
    const { index, correctionType } = action.payload;

    listOfIssues[index].correctionType = correctionType;

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.UNDO_CORRECTION] = () => {
    delete listOfIssues[action.payload.index].correctionType;

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.SET_EDIT_CONTENTION_TEXT] = () => {
    listOfIssues[action.payload.issueIdx].editedDescription = action.payload.editedDescription;

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.ISSUE_WITHDRAW_REQUEST_APPROVED] = () => {
    const { withdrawalDate, requestIssue } = action.payload.issueModificationRequest;

    const index = listOfIssues.findIndex((issue) => issue.id === requestIssue.id);

    listOfIssues[index] = {
      ...listOfIssues[index],
      withdrawalPending: true,
      pendingWithdrawalDate: withdrawalDate
    };

    return {
      ...state,
      addedIssues: listOfIssues
    };
  };

  actionsMap[ACTIONS.ISSUE_ADDITION_REQUEST_APPROVED] = () => {
    let newRequestIssue = action.payload.issueModificationRequest;

    newRequestIssue.addedFromApprovedRequest = true;

    let addedIssues = [...listOfIssues, newRequestIssue];

    return {
      ...state,
      addedIssues,
      issueCount: addedIssues.length
    };
  };

  actionsMap[ACTIONS.SET_ALL_APPROVED_ISSUE_MODIFICATION_WITHDRAWAL_DATES] = () => {
    const calculatedLastPendingWithdrawalDate = pendingIssueModificationRequests
    ?.reduce((latest, current) => {
      // Check if current request is a withdrawal and its status is approved
      if (current.requestType === 'withdrawal' && current.status === 'approved') {
        // If latest is not set yet or current withdrawalDate is later than latest, update latest
        if (!latest || new Date(current.withdrawalDate) > new Date(latest.withdrawalDate)) {
          return current;
        }
      }

      // Return the latest as is if current does not meet criteria or is not later
      return latest;
    }, null)?.withdrawalDate;

    // Prioritize the payload, if there is no withdrawal date in the payload then calculate it
    const updatedWithdrawalDate = action.payload.withdrawalDate || calculatedLastPendingWithdrawalDate;
    // Set all approved withdrawal pending issue modification requests to the updatedWithdrawalDate
    const updatedPendingModificationRequests = pendingIssueModificationRequests.map((request) => {
      if (request.requestType === 'withdrawal' && request.status === 'approved') {
        request.withdrawalDate = updatedWithdrawalDate;
      }

      return request;
    });

    return {
      ...state,
      pendingIssueModificationRequests: updatedPendingModificationRequests
    };
  };

  return actionsMap;
};

export const applyCommonReducers = (state, action) => {
  let reducerFunc = commonReducers(state, action)[action.type];

  return reducerFunc ? reducerFunc() : state;
};

export const commonStateFromServerIntake = (serverIntake) => {
  const contestableIssues = formatContestableIssues(serverIntake.contestableIssuesByDate);

  return {
    isStarted: {
      $set: Boolean(serverIntake.id)
    },
    receiptDate: {
      $set: serverIntake.receipt_date
    },
    filedByVaGov: {
      $set: serverIntake.filedByVaGov
    },
    veteranIsNotClaimant: {
      $set: serverIntake.veteranIsNotClaimant
    },
    claimant: {
      $set: serverIntake.veteranIsNotClaimant ? serverIntake.claimant : null
    },
    claimantType: {
      $set: serverIntake.claimantType
    },
    claimantName: {
      $set: serverIntake.claimantName
    },
    claimantRelationship: {
      $set: serverIntake.claimantRelationship
    },
    powerOfAttorneyName: {
      $set: serverIntake.powerOfAttorneyName
    },
    payeeCode: {
      $set: serverIntake.payeeCode
    },
    processedInCaseflow: {
      $set: serverIntake.processedInCaseflow
    },
    legacyOptInApproved: {
      $set: serverIntake.legacyOptInApproved
    },
    legacyAppeals: {
      $set: serverIntake.legacyAppeals
    },
    isReviewed: {
      $set: Boolean(serverIntake.receipt_date)
    },
    contestableIssues: {
      $set: contestableIssues
    },
    activeNonratingRequestIssues: {
      $set: formatRequestIssues(serverIntake.activeNonratingRequestIssues)
    },
    requestIssues: {
      $set: formatRequestIssues(serverIntake.requestIssues, contestableIssues)
    },
    pendingIssueModificationRequests: {
      $set: formatIssueModificationRequests(serverIntake.pendingIssueModificationRequests)
    },
    isComplete: {
      $set: Boolean(serverIntake.completed_at)
    },
    relationships: {
      $set: formatRelationships(serverIntake.relationships)
    },
    intakeUser: {
      $set: serverIntake.intakeUser
    },
    asyncJobUrl: {
      $set: serverIntake.asyncJobUrl
    },
    processedAt: {
      $set: serverIntake.processedAt
    },
    veteranValid: {
      $set: serverIntake.veteranValid
    },
    homelessness: {
      $set: serverIntake.homelessness
    },
    veteranInvalidFields: {
      $set: {
        veteranMissingFields: serverIntake.veteranInvalidFields.veteran_missing_fields.join(', '),
        veteranAddressTooLong: serverIntake.veteranInvalidFields.veteran_address_too_long,
        veteranAddressInvalidFields: serverIntake.veteranInvalidFields.veteran_address_invalid_fields,
        veteranCityInvalidFields: serverIntake.veteranInvalidFields.veteran_city_invalid_fields,
        veteranCityTooLong: serverIntake.veteranInvalidFields.veteran_city_too_long,
        veteranDateOfBirthInvalid: serverIntake.veteranInvalidFields.veteran_date_of_birth_invalid,
        veteranNameSuffixInvalid: serverIntake.veteranInvalidFields.veteran_name_suffix_invalid,
        veteranZipCodeInvalid: serverIntake.veteranInvalidFields.veteran_zip_code_invalid,
        veteranPayGradeInvalid: serverIntake.veteranInvalidFields.veteran_pay_grade_invalid
      }
    }
  };
};
