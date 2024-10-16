import thunk from 'redux-thunk';
import { applyMiddleware, createStore, compose } from 'redux';
import CombinedNonCompReducer from 'app/nonComp/reducers';

const createNonCompStore = (data) => {
  return createStore(
    CombinedNonCompReducer,
    data,
    compose(applyMiddleware(thunk))
  );
};

export default createNonCompStore;
