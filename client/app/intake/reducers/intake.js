import { ACTIONS, REQUEST_STATE } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatDateStr } from '../../util/DateUtil';
import _ from 'lodash';

const updateFromServerIntake = (state, serverIntake) => {
  return update(state, {
    id: {
      $set: serverIntake.id
    },
    formType: {
      $set: serverIntake.form_type
    },
    asyncJobUrl: {
      $set: serverIntake.async_job_url
    },
    editIssuesUrl: {
      $set: serverIntake.editIssuesUrl
    },
    unreadMessages: {
      $set: serverIntake.unread_messages
    },
    veteran: {
      name: {
        $set: serverIntake.veteran_name
      },
      formName: {
        $set: serverIntake.veteran_form_name
      },
      fileNumber: {
        $set: serverIntake.veteran_file_number
      },
      isDeceased: {
        $set: serverIntake.veteran_is_deceased
      }
    }
  });
};

export const mapDataToInitialIntake = (data = { serverIntake: {} }) => (
  updateFromServerIntake({
    id: null,
    asyncJobUrl: null,
    editIssuesUrl: null,
    formType: null,
    fileNumberSearch: '',
    searchErrorCode: null,
    searchErrorData: {
      duplicateReceiptDate: null,
      duplicateProcessedBy: null,
      veteranMissingFields: null,
      veteranAddressTooLong: null,
      veteranAddressInvalidFields: null,
      veteranCityInvalidFields: null,
      veteranZipCodeInvalid: null,
      veteranPayGradeInvalid: null,
      pids: null
    },
    cancelModalVisible: false,
    unreadMessages: false,
    veteran: {
      name: '',
      formName: '',
      fileNumber: '',
      isDeceased: null
    },
    requestStatus: {
      fileNumberSearch: REQUEST_STATE.NOT_STARTED,
      cancel: REQUEST_STATE.NOT_STARTED
    }
  }, data.serverIntake)
);

const resetIntake = () => mapDataToInitialIntake({ serverIntake: {} });

export const intakeReducer = (state = mapDataToInitialIntake(), action) => {
  switch (action.type) {
  case ACTIONS.START_NEW_INTAKE:
    return resetIntake();
  case ACTIONS.SET_FILE_NUMBER_SEARCH:
    return update(state, {
      fileNumberSearch: {
        $set: action.payload.fileNumber
      }
    });
  case ACTIONS.SET_FORM_TYPE:
    return update(state, {
      formType: {
        $set: action.payload.formType
      }
    });
  case ACTIONS.FILE_NUMBER_SEARCH_START:
    return update(state, {
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.FILE_NUMBER_SEARCH_SUCCEED:
    return updateFromServerIntake(update(state, {
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    }), action.payload.intake);
  case ACTIONS.FILE_NUMBER_SEARCH_FAIL:
    return update(state, {
      searchErrorCode: {
        $set: action.payload.errorCode
      },
      searchErrorData: {
        duplicateReceiptDate: {
          $set: formatDateStr(action.payload.errorData.receipt_date)
        },
        duplicateProcessedBy: {
          $set: action.payload.errorData.processed_by
        },
        veteranMissingFields: {
          $set: _.join(action.payload.errorData.veteran_missing_fields, ', ')
        },
        veteranAddressTooLong: {
          $set: action.payload.errorData.veteran_address_too_long
        },
        veteranAddressInvalidFields: {
          $set: action.payload.errorData.veteran_address_invalid_fields
        },
        veteranCityInvalidFields: {
          $set: action.payload.errorData.veteran_city_invalid_fields
        },
        veteranCityTooLong: {
          $set: action.payload.errorData.veteran_city_too_long
        },
        veteranDateOfBirthInvalid: {
          $set: action.payload.errorData.veteran_date_of_birth_invalid
        },
        veteranNameSuffixInvalid: {
          $set: action.payload.errorData.veteran_name_suffix_invalid
        },
        veteranZipCodeInvalid: {
          $set: action.payload.errorData.veteran_zip_code_invalid
        },
        veteranPayGradeInvalid: {
          $set: action.payload.errorData.veteran_pay_grade_invalid
        },
        pids: {
          $set: _.join(action.payload.errorData.pids, ', ')
        }
      },
      requestStatus: {
        fileNumberSearch: {
          $set: REQUEST_STATE.FAILED
        }
      }
    });
  case ACTIONS.CLEAR_SEARCH_ERRORS:
    return update(state, {
      searchErrorCode: {
        $set: null
      },
      searchErrorData: {
        duplicateReceiptDate: {
          $set: null
        },
        duplicateProcessedBy: {
          $set: null
        },
        veteranMissingFields: {
          $set: null
        },
        veteranAddressTooLong: {
          $set: null
        },
        veteranAddressInvalidFields: {
          $set: null
        },
        veteranCityInvalidFields: {
          $set: null
        },
        veteranZipCodeInvalid: {
          $set: null
        },
        veteranPayGradeInvalid: {
          $set: null
        },
        pids: {
          $set: null
        }
      }
    });
  case ACTIONS.CANCEL_INTAKE_START:
    return update(state, {
      requestStatus: {
        cancel: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.CANCEL_INTAKE_FAIL:
    return update(state, {
      requestStatus: {
        cancel: {
          $set: REQUEST_STATE.FAILED
        }
      },
      $toggle: ['cancelModalVisible']
    });
  case ACTIONS.CANCEL_INTAKE_SUCCEED:
    return update(resetIntake(), {
      requestStatus: {
        cancel: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      }
    });
  case ACTIONS.TOGGLE_CANCEL_MODAL:
    return update(state, {
      $toggle: ['cancelModalVisible']
    });
  default:
    return state;
  }
};
