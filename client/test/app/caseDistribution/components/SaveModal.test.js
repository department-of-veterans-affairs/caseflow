import React from 'react';
import { render, waitFor} from '@testing-library/react';
import SaveModal from 'app/caseDistribution/components/SaveModal';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { testingBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Save Modal', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversWithTestingBatchLevers = { batch: testingBatchLevers };
  // let lever = testingBatchLevers[0];

  it('renders Save Modal for Admin Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal />
      </Provider>
    );
    expect(document.querySelector('#modal_id-title')).toHaveTextContent('Confirm Case Distribution Algorithm Changes');
  });
});
