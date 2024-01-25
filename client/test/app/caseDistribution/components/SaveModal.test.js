import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import SaveModal from 'app/caseDistribution/components/SaveModal';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import * as changedLevers from 'app/caseDistribution/reducers/levers/leversSelector';
import { modalOriginalTestLevers } from '../../../data/adminCaseDistributionLevers';
import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';
// import * as utils from 'app/caseDistribution/utils';

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

  it('displays the changed levers for Alternative Batch Size', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    const handleConfirmButton = jest.fn();

    const changedLeversData = [
      {
        title: 'Alternate Batch Size*',
        backendValue: '50',
        value: '15',
        data_type: 'number'
      },
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

  it('displays the changed levers for Affinity Days', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    const handleConfirmButton = jest.fn();

    const changedLeversData = [
      {
        title: 'AOJ AOD Affinity Days',
        backendValue: '15',
        data_type: 'radio',
        value: 'text',
        options: [
          {
            item: 'text',
            value: '14',
            unit: 'days'
          }
        ]
      }
    ];

    jest.spyOn(changedLevers, 'changedLevers').mockReturnValue(changedLeversData);

    jest.mock('app/caseDistribution/utils', () => ({
      ...jest.requireActual('app/caseDistribution/utls'),
      findOption: jest.fn((lever, value) => {
        // Use the first lever from changedLeversData for mocking
        return {
          item: 'text',
          value: '12',
          title: 'Option 1'
        };

        // Provide a default return value if needed
      }),
    }));
    store.dispatch(loadLevers(leversOfModalOriginalTestLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal setShowModal={setShowModal} handleConfirmButton={handleConfirmButton} />
      </Provider>
    );

    for (const leverData of changedLeversData) {
      expect(screen.getByText(leverData.title)).toBeInTheDocument();
      expect(screen.getByText(leverData.options.value)).toBeInTheDocument();
    }
  });

  it('closes the modal when cancel button is clicked', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    store.dispatch(loadLevers(leversOfModalOriginalTestLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal
          setShowModal={setShowModal}
        />
      </Provider>
    );

    const cancelButton = screen.getByText('Cancel');

    userEvent.click(cancelButton);

    expect(setShowModal).toHaveBeenCalledWith(false);
  });
});
