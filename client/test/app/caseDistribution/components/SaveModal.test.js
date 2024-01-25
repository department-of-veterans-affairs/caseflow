import React from 'react';
import { render, screen } from '@testing-library/react';
import SaveModal from 'app/caseDistribution/components/SaveModal';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import * as changedLevers from 'app/caseDistribution/reducers/levers/leversSelector';
import { modalOriginalTestLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';

describe('Save Modal', () => {

  const getStore = () => createStore(
    rootReducer,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  let leversOfModalOriginalTestLevers = { batch: modalOriginalTestLevers };

  it('renders Save Modal for Admin Users', () => {
    const store = getStore();

    let handleConfirmButton = jest.fn().mockImplementation(() => {
      'Confirm';
    });
    let setShowModal = jest.fn().mockImplementation((display) => display);

    store.dispatch(loadLevers(leversOfModalOriginalTestLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal setShowModal={setShowModal} handleConfirmButton={handleConfirmButton} />
      </Provider>
    );
    expect(document.querySelector('#modal_id-title')).toHaveTextContent('Confirm Case Distribution Algorithm Changes');
  });

  it('displays the changed levers', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    const handleConfirmButton = jest.fn();

    const changedLeversData = [
      { title: 'Alternate Batch Size*',
        backendValue: '50',
        value: '15',
        data_type: 'number' },
    ];

    jest.spyOn(changedLevers, 'changedLevers').mockReturnValue(changedLeversData);

    store.dispatch(loadLevers(leversOfModalOriginalTestLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal setShowModal={setShowModal} handleConfirmButton={handleConfirmButton} />
      </Provider>
    );

    for (const leverData of changedLeversData) {
      expect(screen.getByText(leverData.title)).toBeInTheDocument();
      expect(screen.getByText(leverData.value)).toBeInTheDocument();
    }
  });
});
