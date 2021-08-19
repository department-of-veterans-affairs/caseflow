// shared functions between reducers
import { ACTIONS } from '../constants';
import { formatRelationships } from '../util';
import { formatRequestIssues, formatContestableIssues } from '../util/issues';
import { update } from '../../util/ReducerUtil';

export const commonReducers = (state, action) => {
  let actionsMap = {};
  let listOfIssues = state.addedIssues ? state.addedIssues : [];

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
    veteranInvalidFields: {
      $set: {
        veteranMissingFields: _.join(serverIntake.veteranInvalidFields.veteran_missing_fields, ', '),
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
