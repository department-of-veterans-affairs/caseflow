import { ACTIONS } from './caseflowDistributionAdminConstants';

export const testRedux = (data) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.TEST_REDUX,
      payload: {
        data
      }
    });
  };
