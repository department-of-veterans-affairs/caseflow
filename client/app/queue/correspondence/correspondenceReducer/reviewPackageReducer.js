import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './reviewPackageConstants';

export const initialState = {
  correspondence: {},
  correspondenceDocuments: [],
  packageDocumentType: {},
  veteranInformation: {}
};

export const reviewPackageReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.SET_CORRESPONDENCE:
    return update(state, {
      correspondence: {
        $set: action.payload.correspondence
      }
    });

  case ACTIONS.SET_CORRESPONDENCE_DOCUMENTS:
    return update(state, {
      correspondenceDocuments: {
        $set: action.payload.correspondenceDocuments
      }
    });

  case ACTIONS.SET_PACKAGE_DOCUMENT_TYPE:
    return update(state, {
      packageDocumentType: {
        $set: action.payload.packageDocumentType
      }
    });

  case ACTIONS.SET_VETERAN_INFORMATION:
    return update(state, {
      veteranInformation: {
        $set: action.payload.veteranInfo
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

  default:
    return state;
  }
};

export default reviewPackageReducer;
