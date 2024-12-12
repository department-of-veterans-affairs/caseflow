import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './reviewPackageConstants';

export const initialState = {
  correspondence: {},
  correspondenceDocuments: [],
  packageDocumentType: {},
  lastAction: {},
  taskInstructions: [],
  reasonForRemovePackage: {},
  createRecordIsReadOnly: 'Select...',
  autoAssign: {
    isButtonDisabled: false,
    batchId: null,
    bannerAlert: {},
  },
  reasonForReassignPackage: {}
};

export const reviewPackageReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.SET_CORRESPONDENCE:
    return update(state, {
      correspondence: {
        $set: action.payload.correspondence
      }
    });

  case ACTIONS.SET_PACKAGE_DOCUMENT_TYPE:
    return update(state, {
      packageDocumentType: {
        $set: action.payload.packageDocumentType
      }
    });

  case ACTIONS.CREATE_RECORD_IS_READ_ONLY:

    return update(state, {

      createRecordIsReadOnly: {
        $set: action.payload.createRecordIsReadOnly
      }
    });

  case ACTIONS.UPDATE_CMP_INFORMATION:
    return update(state, {
      correspondence: {
        va_date_of_receipt: {
          $set: action.payload.date
        }
      },
      packageDocumentType: {
        id: {
          $set: action.payload.packageDocumentType.value
        },
        name: {
          $set: action.payload.packageDocumentType.label
        }
      }
    });

  case ACTIONS.UPDATE_DOCUMENT_TYPE_NAME:
    return update(state, {
      correspondence: {
        correspondenceDocuments: {
          [action.payload.index]: {
            vbms_document_type_id: {
              $set: action.payload.newName.value
            },
            document_title: {
              $set: action.payload.newName.label
            }
          }
        }
      }
    });

  case ACTIONS.REMOVE_PACKAGE_ACTION:
    return update(state, {
      lastAction: {
        action_type: {
          $set: action.payload.currentAction
        }
      }
    });

  case ACTIONS.SET_TASK_INSTRUCTIONS:
    return update(state, {
      taskInstructions: {
        $set: action.payload.taskInstructions
      }
    });

  case ACTIONS.SET_BATCH_AUTO_ASSIGN_ATTEMPT_ID:
    return update(state, {
      autoAssign: {
        batchId: {
          $set: action.payload.batchId
        }
      }
    });

  case ACTIONS.REASSIGN_PACKAGE_ACTION:
    return update(state, {
      lastAction: {
        action_type: {
          $set: action.payload.currentAction
        }
      }
    });

  case ACTIONS.SET_AUTO_ASSIGN_BANNER:
    return update(state, {
      autoAssign: {
        bannerAlert: {
          title: { $set: action.payload.title },
          message: { $set: action.payload.message },
          type: { $set: action.payload.type }
        }
      }
    });

  case ACTIONS.SET_AUTO_ASSIGN_BUTTON_DISABLED:
    return update(state, {
      autoAssign: {
        isButtonDisabled: {
          $set: action.payload.isButtonDisabled
        }
      }
    });

  default:
    return state;
  }
};

export default reviewPackageReducer;
