import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './uiConstants';

const initialSaveState = {
  savePending: false,
  saveSuccessful: null
};

export const initialState = {
  selectingJudge: false,
  highlightFormItems: false,
  messages: {
    success: null,
    error: null
  },
  saveState: initialSaveState,
  modals: {},
  featureToggles: {},
  userRole: '',
  userCssId: '',
  organizations: [],
  activeOrganization: {
    id: null,
    name: null,
    isVso: false
  },
  userIsVsoEmployee: false,
  feedbackUrl: '#',
  loadedUserId: null,
  selectedAssignee: null,
  selectedAssigneeSecondary: null,
  veteranCaseListIsVisible: false,
  canEditAod: false,
  canEditNodDate: false,
  userIsCobAdmin: false,
  canEditCavcRemands: false,
  hearingDay: {
    hearingDate: null,
    regionalOffice: null
  },
  targetUser : {},
  poaAlert: {}
};

const setMessageState = (state, message, msgType) => update(state, {
  messages: {
    [msgType]: {
      $set: message
    }
  }
});

const setErrorMessageState = (state, message) => setMessageState(state, message, 'error');
const hideErrorMessage = (state) => setErrorMessageState(state, null);
const showErrorMessage = (state, errorMsg = { title: 'Error' }) => setErrorMessageState(state, errorMsg);

const setSuccessMessageState = (state, message) => setMessageState(state, message, 'success');
const hideSuccessMessage = (state) => setSuccessMessageState(state, null);
const showSuccessMessage = (state, message = { title: 'Success' }) => setSuccessMessageState(state, message);

const setModalState = (state, visibility, modalType) => update(state, {
  modals: {
    [modalType]: {
      $set: visibility
    }
  }
});

const showModal = (state, modalType) => setModalState(state, true, modalType);
const hideModal = (state, modalType) => setModalState(state, false, modalType);

const workQueueUiReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.SET_POA_REFRESH_ALERT:
    return update(state, {
      poaAlert: {
        alertType: { $set: action.payload.alertType },
        message: { $set: action.payload.message },
        powerOfAttorney: { $set: action.payload.powerOfAttorney }
      }
    });
  case ACTIONS.SET_SELECTING_JUDGE:
    return update(state, {
      selectingJudge: { $set: action.payload.selectingJudge }
    });
  case ACTIONS.SET_CAN_EDIT_AOD:
    return update(state, {
      canEditAod: { $set: action.payload.canEditAod }
    });
  case ACTIONS.SET_CAN_EDIT_NOD_DATE:
    return update(state, {
      canEditNodDate: { $set: action.payload.canEditNodDate }
    });
  case ACTIONS.SET_USER_IS_COB_ADMIN:
    return update(state, {
      userIsCobAdmin: { $set: action.payload.userIsCobAdmin }
    });
  case ACTIONS.SET_CAN_EDIT_CAVC_REMANDS:
    return update(state, {
      canEditCavcRemands: { $set: action.payload.canEditCavcRemands }
    });
  case ACTIONS.SET_CAN_VIEW_OVERTIME_STATUS:
    return update(state, {
      canViewOvertimeStatus: { $set: action.payload.canViewOvertimeStatus }
    });
  case ACTIONS.HIGHLIGHT_INVALID_FORM_ITEMS:
    return update(state, {
      highlightFormItems: {
        $set: action.payload.highlight
      }
    });
  case ACTIONS.REQUEST_SAVE:
    return update(state, {
      saveState: {
        savePending: { $set: true },
        saveSuccessful: { $set: null }
      }
    });
  case ACTIONS.SAVE_SUCCESS:
    return update(state, {
      saveState: {
        savePending: { $set: false },
        saveSuccessful: { $set: true }
      }
    });
  case ACTIONS.SAVE_FAILURE:
    return update(state, {
      saveState: {
        savePending: { $set: false },
        saveSuccessful: { $set: false }
      }
    });
  case ACTIONS.RESET_SAVE_STATE:
    return update(state, {
      saveState: { $set: initialSaveState }
    });
  case ACTIONS.RESET_ERROR_MESSAGES:
    return update(state, {
      messages: {
        error: { $set: null }
      }
    });
  case ACTIONS.RESET_SUCCESS_MESSAGES:
    return update(state, {
      messages: {
        success: { $set: null }
      }
    });
  case ACTIONS.HIDE_ERROR_MESSAGE:
    return hideErrorMessage(state);
  case ACTIONS.SHOW_ERROR_MESSAGE:
    return showErrorMessage(state, action.payload.errorMessage);
  case ACTIONS.SHOW_SUCCESS_MESSAGE:
    return showSuccessMessage(state, action.payload.message);
  case ACTIONS.HIDE_SUCCESS_MESSAGE:
    return hideSuccessMessage(state);
  case ACTIONS.SHOW_MODAL:
    return showModal(state, action.payload.modalType);
  case ACTIONS.HIDE_MODAL:
    return hideModal(state, action.payload.modalType);
  case ACTIONS.SET_FEATURE_TOGGLES:
    return update(state, {
      featureToggles: {
        $set: action.payload.featureToggles
      }
    });
  case ACTIONS.TOGGLE_VETERAN_CASE_LIST:
    return update(state, {
      veteranCaseListIsVisible: { $set: !state.veteranCaseListIsVisible }
    });
  case ACTIONS.SHOW_VETERAN_CASE_LIST:
    return update(state, {
      veteranCaseListIsVisible: { $set: true }
    });
  case ACTIONS.HIDE_VETERAN_CASE_LIST:
    return update(state, {
      veteranCaseListIsVisible: { $set: false }
    });
  case ACTIONS.SET_USER_ID:
    return update(state, {
      loadedUserId: { $set: action.payload.userId }
    });
  case ACTIONS.SET_USER_ROLE:
    return update(state, {
      userRole: { $set: action.payload.userRole }
    });
  case ACTIONS.SET_USER_CSS_ID:
    return update(state, {
      userCssId: { $set: action.payload.cssId }
    });
  case ACTIONS.SET_TARGET_USER:
    return update(state, {
      targetUser: {
        id: { $set: action.payload.targetUser.id },
        cssId: { $set: action.payload.targetUser.css_id },
        fullName: { $set: action.payload.targetUser.full_name },
        displayName: { $set: action.payload.targetUser.display_name },
        status: { $set: action.payload.targetUser.status },
        roles: { $set: action.payload.targetUser.roles },
        selectedRegionalOffice: { $set: action.payload.targetUser.selected_regional_office }
      }
    });
  case ACTIONS.SET_USER_IS_VSO_EMPLOYEE:
    return update(state, {
      userIsVsoEmployee: { $set: action.payload.userIsVsoEmployee }
    });
  case ACTIONS.SET_FEEDBACK_URL:
    return update(state, {
      feedbackUrl: { $set: action.payload.feedbackUrl }
    });
  case ACTIONS.SET_SELECTED_ASSIGNEE:
    return update(state, {
      selectedAssignee: {
        $set: action.payload.assigneeId
      }
    });
  case ACTIONS.SET_SELECTED_ASSIGNEE_SECONDARY:
    return update(state, {
      selectedAssigneeSecondary: {
        $set: action.payload.assigneeId
      }
    });
  case ACTIONS.RESET_ASSIGNEES:
    return update(state, {
      selectedAssigneeSecondary: {
        $set: null
      }, selectedAssignee: {
        $set: null
      }
    });
  case ACTIONS.SET_ORGANIZATIONS:
    return update(state, {
      organizations: {
        $set: action.payload.organizations
      }
    });
  case ACTIONS.SET_ACTIVE_ORGANIZATION:
    return update(state, {
      activeOrganization: {
        id: { $set: action.payload.id },
        name: { $set: action.payload.name },
        isVso: { $set: action.payload.isVso },
        userCanBulkAssign: { $set: action.payload.userCanBulkAssign }
      }
    });
  case ACTIONS.SET_HEARING_DAY:
    return update(state, {
      hearingDay: {
        $set: action.payload
      }
    });
  default:
    return state;
  }
};

export default workQueueUiReducer;
