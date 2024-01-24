import React from 'react';
import { render, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import SaveModal from '../../../../app/caseDistribution/components/SaveModal';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { modalOriginalTestLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin, updateNumberLever, updateCombinationLever } from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';

describe('Save Modal', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let batchSizeLevers = modalOriginalTestLevers.filter((lever) => (lever.lever_group === 'batch'));
  let docketDistPriorLevers = modalOriginalTestLevers.filter((lever) => (lever.lever_group === 'docket_distribution_prior'));

  let levers = {
    docket_distribution_prior: docketDistPriorLevers,
    batch: batchSizeLevers,
  }

  it('renders the Save Modal for Complex Logic Levers', () => {
    const store = getStore();

    let handleConfirmButton = jest.fn().mockImplementation(() => {
      'Confirm';
    });
    let setShowModal = jest.fn().mockImplementation((display) => display);

    store.dispatch(setUserIsAcdAdmin(false));
    store.dispatch(loadLevers(levers));

    store.dispatch(updateCombinationLever('docket_distribution_prior', 'modal-test-combination-lever', '42'));
    store.dispatch(updateNumberLever('batch', 'modal-test-number-lever', '94'));

    render(
      <Provider store={store}>
        <SaveModal setShowModal={setShowModal} handleConfirmButton={handleConfirmButton} />
      </Provider>
    );
    expect(document.querySelector('#modal_id-title')).toBeTruthy();
  });
});
