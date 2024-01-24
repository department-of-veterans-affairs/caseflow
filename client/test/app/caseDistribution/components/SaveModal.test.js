import React from 'react';
import { render, waitFor} from '@testing-library/react';
import SaveModal from 'app/caseDistribution/components/SaveModal';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
<<<<<<< HEAD
import { testingBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';
=======
import { modalOriginalTestLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin, updateNumberLever, updateCombinationLever } from 'app/caseDistribution/reducers/levers/leversActions';
>>>>>>> bac20f24fabefb49366e23594d8610a3281ad322
import { mount } from 'enzyme';

describe('Save Modal', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

<<<<<<< HEAD
  let leversWithTestingBatchLevers = { batch: testingBatchLevers };
  // let lever = testingBatchLevers[0];

  it('renders Save Modal for Admin Users', () => {
    const store = getStore();

    store.dispatch(loadLevers(leversWithTestingBatchLevers));
=======
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

>>>>>>> bac20f24fabefb49366e23594d8610a3281ad322
    store.dispatch(setUserIsAcdAdmin(false));
    store.dispatch(loadLevers(levers));

<<<<<<< HEAD
=======
    store.dispatch(updateCombinationLever('docket_distribution_prior', 'modal-test-combination-lever', '42'));
    store.dispatch(updateNumberLever('batch', 'modal-test-number-lever', '94'));

>>>>>>> bac20f24fabefb49366e23594d8610a3281ad322
    render(
      <Provider store={store}>
        <SaveModal />
      </Provider>
    );
<<<<<<< HEAD
    expect(document.querySelector('#modal_id-title')).toHaveTextContent('Confirm Case Distribution Algorithm Changes');
=======
    expect(document.querySelector('#modal_id-title')).toBeTruthy();
>>>>>>> bac20f24fabefb49366e23594d8610a3281ad322
  });
});
