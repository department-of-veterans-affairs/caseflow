import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './cavcDashboardConstants';

export const initialState = {
  decision_reasons: [],
  selection_bases: [],
  initial_state: {
    cavc_dashboards: [],
    checked_boxes: {}
  },
  cavc_dashboards: [],
  checked_boxes: {},
  dashboard_issues: [],
  error: {}
};

export const cavcDashboardReducer = (state = initialState, action) => {
  switch (action.type) {
  case ACTIONS.FETCH_CAVC_DECISION_REASONS:
    return update(state, {
      decision_reasons: {
        $set: action.payload.decision_reasons
      }
    });
  case ACTIONS.FETCH_CAVC_SELECTION_BASES:
    return update(state, {
      selection_bases: {
        $set: action.payload.selection_bases
      }
    });
  case ACTIONS.FETCH_INITIAL_DASHBOARD_DATA:
    return update(state, {
      initial_state: {
        cavc_dashboards: {
          $set: action.payload.cavc_dashboards
        },
        checked_boxes: {}
      },
      cavc_dashboards: {
        $set: action.payload.cavc_dashboards
      }
    });
  case ACTIONS.RESET_DASHBOARD_DATA:
    return update(state, {
      $set: initialState
    });
  case ACTIONS.SET_CHECKED_DECISION_REASONS:
    return update(state, {
      checked_boxes: {
        [action.payload.issueId]: {
          $set: action.payload.checkedReasons
        }
      }
    });
  case ACTIONS.SET_BASIS_FOR_REASON_CHECKBOX:
    if (action.payload.parentCheckboxId) {
      const childCheckboxIndex =
        state.checked_boxes[action.payload.issueId][action.payload.parentCheckboxId].children.
          findIndex((child) => child.id === action.payload.checkboxId);

      return update(state, {
        checked_boxes: {
          [action.payload.issueId]: {
            [action.payload.parentCheckboxId]: {
              children: {
                [childCheckboxIndex]: {
                  selection_bases: {
                    [action.payload.selectionBasesIndex]: {
                      $merge: {
                        label: action.payload.label,
                        value: action.payload.value,
                        category: action.payload.category
                      }
                    }
                  }
                }
              }
            }
          }
        }
      });
    }

    return update(state, {
      checked_boxes: {
        [action.payload.issueId]: {
          [action.payload.checkboxId]: {
            selection_bases: {
              [action.payload.selectionBasesIndex]: {
                $merge: {
                  label: action.payload.label,
                  value: action.payload.value
                }
              }
            }
          }
        }
      }
    });
  case ACTIONS.SET_INITIAL_CHECKED_DECISION_REASONS:
    return update(state, {
      initial_state: {
        checked_boxes: {
          [action.payload.uniqueId]: {
            $set: state.checked_boxes[action.payload.uniqueId]
          }
        }
      }
    });
  case ACTIONS.REMOVE_CHECKED_DECISION_REASON:
    return update(state, {
      checked_boxes: {
        $unset: action.payload.issueId
      }
    });
  case ACTIONS.UPDATE_DASHBOARD_ISSUES:
    return update(state, {
      cavc_dashboards: {
        [action.payload.dashboardIndex]: {
          cavc_dashboard_issues: {
            $push: [action.payload.issue]
          },
          cavc_dashboard_dispositions: {
            $push: [action.payload.dashboardDisposition]
          }
        }
      }
    });
  case ACTIONS.SET_DISPOSITION_VALUE: {
    // case block is wrapped in brackets to contain this constant in local scope
    let dispositionIndex = state.
      cavc_dashboards[action.payload.dashboardIndex].
      cavc_dashboard_dispositions.
      findIndex((dis) => dis.cavc_dashboard_issue_id === action.payload.dispositionIssueId);

    if (dispositionIndex === -1) {
      dispositionIndex = state.
        cavc_dashboards[action.payload.dashboardIndex].
        cavc_dashboard_dispositions.
        findIndex((dis) => dis.request_issue_id === action.payload.dispositionIssueId);
    }

    return update(state, {
      cavc_dashboards: {
        [action.payload.dashboardIndex]: {
          cavc_dashboard_dispositions: {
            [dispositionIndex]: {
              disposition: {
                $set: action.payload.dispositionOption
              }
            }
          }
        }
      }
    });
  }
  case ACTIONS.REMOVE_DASHBOARD_ISSUE: {
    const cavcDashboardIssues = state.cavc_dashboards[action.payload.dashboardIndex].
      cavc_dashboard_issues.filter((issue) => issue !== action.payload.issue);
    const cavcDashboardDispositions = state.cavc_dashboards[action.payload.dashboardIndex].
      cavc_dashboard_dispositions.filter((dis) => dis.cavc_dashboard_issue_id !== action.payload.issue.id);

    return update(state, {
      cavc_dashboards: {
        [action.payload.dashboardIndex]: {
          cavc_dashboard_issues: {
            $set: cavcDashboardIssues
          },
          cavc_dashboard_dispositions: {
            $set: cavcDashboardDispositions
          }
        }
      }
    });
  }
  case ACTIONS.UPDATE_DASHBOARD_DATA:
    return update(state, {
      cavc_dashboards: {
        [action.payload.dashboardIndex]: {
          board_decision_date: {
            $set: action.payload.updatedData.boardDecisionDateUpdate
          },
          board_docket_number: {
            $set: action.payload.updatedData.boardDocketNumberUpdate
          },
          cavc_decision_date: {
            $set: action.payload.updatedData.cavcDecisionDateUpdate
          },
          cavc_docket_number: {
            $set: action.payload.updatedData.cavcDocketNumberUpdate
          },
          joint_motion_for_remand: {
            $set: action.payload.updatedData.jointMotionForRemandUpdate
          }
        }
      }
    });
  case ACTIONS.SAVE_DASHBOARD_DATA_FAILURE:
    return update(state, {
      error: {
        message: {
          $set: action.payload.responseError
        }
      }
    });
  default:
    return state;
  }
};

export default cavcDashboardReducer;
