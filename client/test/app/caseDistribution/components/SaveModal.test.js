import React from 'react';
import { render, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import SaveModal from '../../../../app/caseDistribution/components/SaveModal';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { levers, testingBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Save Modal', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let batchSizeLevers = levers.filter((lever) => (lever.lever_group === 'batch'));
  let leversWithBatchLevers = { batch: batchSizeLevers };

  it('renders the Save Modal for Member Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithBatchLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal />
      </Provider>
    );
    expect(document.querySelector('#modal_id-title')).toBeNull();
  });
});
