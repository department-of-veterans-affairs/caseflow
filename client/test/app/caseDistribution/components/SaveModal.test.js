import React from 'react';
import { render, waitFor, fireEvent } from '@testing-library/react';
import { Provider } from 'react-redux';
import SaveModal from '../../../../app/caseDistribution/components/SaveModal';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { levers, testingBatchLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';
import { mount } from 'enzyme';
import COPY from '../../../../COPY';

describe('Save Modal', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let batchSizeLevers = levers.filter((lever) => (lever.lever_group === 'batch'));
  let leversWithBatchLevers = { batch: batchSizeLevers };

  it('renders the Save Modal for Member Users', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    let handleConfirmButton = jest.fn().mockImplementation(() => {
      'Confirm';
    });

    store.dispatch(loadLevers(leversWithBatchLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    const { getByText } = render(
      <Provider store={store}>
        <SaveModal setShowModal={setShowModal} handleConfirmButton={handleConfirmButton} />
      </Provider>
    );

    fireEvent.click(getByText(COPY.MODAL_CONFIRM_BUTTON));

    await waitFor(() => {});

    console.debug('setShowModal calls:', setShowModal.mock.calls);

    expect(setShowModal).toHaveBeenCalledWith(false);
    expect(handleConfirmButton).toHaveBeenCalled();
  });
});
