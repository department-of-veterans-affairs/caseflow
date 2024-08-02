import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/caseDistribution/reducers/root';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import SaveModal from 'app/caseDistribution/components/SaveModal';
import * as changedLevers from 'app/caseDistribution/reducers/levers/leversSelector';

import {
  mockBatchLevers,
  mockDocketDistributionPriorLevers,
  mockAffinityDaysLevers,
  mockStaticLevers,
  mockDocketTimeGoalsLevers,
} from 'test/data/adminCaseDistributionLevers';

let mockInitialLevers = {
  static: mockStaticLevers,
  batch: mockBatchLevers,
  affinity: mockAffinityDaysLevers,
  docket_distribution_prior: mockDocketDistributionPriorLevers,
  docket_time_goal: mockDocketTimeGoalsLevers,
};

import { loadLevers, setUserIsAcdAdmin } from 'app/caseDistribution/reducers/levers/leversActions';

const initialState = {
  caseDistributionLevers: {
    levers: mockInitialLevers,
    isUserAcdAdmin: true,
  }
};

describe('Save Modal', () => {

  const getStore = () => createStore(
    rootReducer,
    initialState,
    applyMiddleware(thunk));

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders Save Modal for Admin Users', () => {
    const store = getStore();

    let handleConfirmButton = jest.fn().mockImplementation(() => {
      'Confirm';
    });
    let setShowModal = jest.fn().mockImplementation((display) => display);

    store.dispatch(loadLevers(mockInitialLevers));
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
        data_type: 'number',
        value: '15'
      },
    ];

    jest.spyOn(changedLevers, 'changedLevers').mockReturnValue(changedLeversData);

    store.dispatch(loadLevers(mockInitialLevers));
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

  it('displays the changed levers for Affinity Days when infinite radio option is chosen', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    const handleConfirmButton = jest.fn();

    const changedLeversData = [
      {
        title: 'AMA Hearing Case Affinity Days',
        backendValue: '21',
        data_type: 'radio',
        value: 'infinite',
        options: [
          {
            item: 'value',
            value: '21',
            text: 'Attempt distribution to current judge for max of:',
            unit: '',
            data_type: '',
          },
          {
            item: 'infinite',
            value: 'infinite',
            text: 'Always distribute to current judge',
            unit: '',
            data_type: '',
            selected: true,
          },
        ],
        is_toggle_active: true,
      }
    ];

    jest.spyOn(changedLevers, 'changedLevers').mockReturnValue(changedLeversData);

    jest.mock('app/caseDistribution/utils', () => ({
      ...jest.requireActual('app/caseDistribution/utils'),
      findOption: jest.fn((lever, value) => {
        return lever.options.find((option) => option.item === value) || null;
      }),
    }));
    store.dispatch(loadLevers(mockInitialLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal setShowModal={setShowModal} handleConfirmButton={handleConfirmButton} />
      </Provider>
    );
    // This has been changed from value to omit
    for (const leverData of changedLeversData) {
      expect(screen.getByText(leverData.title)).toBeInTheDocument();
      expect(document.querySelector(`#${leverData.item}-title-in-modal`)).toHaveTextContent(leverData.title);
      expect(document.querySelector(`#${leverData.item}-previous-value`)).toHaveTextContent(leverData.backendValue);
      expect(document.querySelector(`#${leverData.item}-new-value`)).toHaveTextContent(leverData.options[1].text);
    }
  });

  it('displays the changed levers for Affinity Days when omit radio option is chosen', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    const handleConfirmButton = jest.fn();

    const changedLeversData = [
      {
        title: 'AMA Hearing Case Affinity Days',
        backendValue: '35',
        data_type: 'radio',
        value: 'omit',
        options: [
          {
            item: 'value',
            value: '1',
            text: 'Literally anything',
            unit: '',
            data_type: '',
          },
          {
            item: 'omit',
            value: 'omit',
            text: 'Omit variable from distribution rules',
            unit: '',
            data_type: '',
            selected: true,
          },
        ],
        is_toggle_active: true,
      }
    ];

    jest.spyOn(changedLevers, 'changedLevers').mockReturnValue(changedLeversData);

    jest.mock('app/caseDistribution/utils', () => ({
      ...jest.requireActual('app/caseDistribution/utils'),
      findOption: jest.fn((lever, value) => {
        return lever.options.find((option) => option.item === value) || null;
      }),
    }));
    store.dispatch(loadLevers(mockInitialLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal setShowModal={setShowModal} handleConfirmButton={handleConfirmButton} />
      </Provider>
    );
    // This has been changed from value to omit
    for (const leverData of changedLeversData) {
      expect(screen.getByText(leverData.title)).toBeInTheDocument();
      expect(document.querySelector(`#${leverData.item}-title-in-modal`)).toHaveTextContent(leverData.title);
      expect(document.querySelector(`#${leverData.item}-previous-value`)).toHaveTextContent(leverData.backendValue);
      expect(document.querySelector(`#${leverData.item}-new-value`)).toHaveTextContent(leverData.options[1].text);
    }
  });

  it('displays the changed levers for Affinity Days when combination radio option is chosen', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    const handleConfirmButton = jest.fn();

    const changedLeversData = [
      {
        title: 'AMA Hearing Case Affinity Days',
        backendValue: '35',
        data_type: 'radio',
        value: 80,
        options: [
          {
            item: 'infinite',
            value: 'infinite',
            text: 'Always distribute to current judge',
            unit: '',
            data_type: '',
          },
          {
            item: 'value',
            data_type: 'number',
            value: 80,
            text: 'Attempt distribution to current judge for max of:',
            unit: 'days',
            selected: true,
          },
        ],
        is_toggle_active: true,
      }
    ];

    jest.spyOn(changedLevers, 'changedLevers').mockReturnValue(changedLeversData);

    jest.mock('app/caseDistribution/utils', () => ({
      ...jest.requireActual('app/caseDistribution/utils'),
      findOption: jest.fn((lever, value) => {
        return lever.options.find((option) => option.item === value) || null;
      }),
    }));
    store.dispatch(loadLevers(mockInitialLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal setShowModal={setShowModal} handleConfirmButton={handleConfirmButton} />
      </Provider>
    );

    for (const leverData of changedLeversData) {
      expect(screen.getByText(leverData.title)).toBeInTheDocument();
      expect(document.querySelector(`#${leverData.item}-title-in-modal`)).toHaveTextContent(leverData.title);
      expect(document.querySelector(`#${leverData.item}-previous-value`)).toHaveTextContent(leverData.backendValue);
      expect(document.querySelector(`#${leverData.item}-new-value`)).toHaveTextContent(leverData.options[1].text);
    }
  });

  it('closes the modal when cancel button is clicked', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    store.dispatch(loadLevers(mockInitialLevers));
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

  it('closes the modal when X button is clicked', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    store.dispatch(loadLevers(mockInitialLevers));
    store.dispatch(setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <SaveModal
          setShowModal={setShowModal}
        />
      </Provider>
    );

    const closeButton = document.querySelector('#Confirm-Case-Distribution-Algorithm-Changes-button-id-close > svg');

    userEvent.click(closeButton);

    expect(setShowModal).toHaveBeenCalledWith(false);
  });
});
