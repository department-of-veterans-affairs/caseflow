import { applyMiddleware, createStore } from 'redux';
import logger from 'redux-logger';
import manageEstablishClaimReducer, { getManageEstablishClaimInitialState } from './index';
import ConfigUtil from '../../util/ConfigUtil';

export const createManageEstablishClaimStore = (props) => {
  let middleware = [];

  // Avoid all the log spam when running the tests
  if (!ConfigUtil.test()) {
    middleware.push(logger);
  }

  return createStore(
    manageEstablishClaimReducer,
    getManageEstablishClaimInitialState(props),
    applyMiddleware(...middleware)
  );
};
