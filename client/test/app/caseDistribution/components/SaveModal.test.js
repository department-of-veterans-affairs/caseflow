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

  it('displays the changed levers for Affinity Days', async () => {
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
      findValueOption: jest.fn().mockImplementation((lever) => {
        return lever.options.find((option) => option.item === 'value') || null;
      }),
      radioValueOptionSelected: jest.fn().mockImplementation((item) => {
        return item === 'value';
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
      expect(document.querySelector(`#${leverData.item}-new-value`)).toHaveTextContent(leverData.options[0].value);
    }
  });

  it('displays the changed levers for Affinity Days when a radio option is chosen', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    const handleConfirmButton = jest.fn();

    const changedLeversData = [
      {
        title: 'AOJ AOD Affinity Days',
        backendValue: '35',
        data_type: 'radio',
        value: 'omit',
        options: [
          {
            item: 'omit',
            text: 'Omit variable from distribution rules',
            unit: '',
            data_type: ''
          }
        ]
      }
    ];

    jest.spyOn(changedLevers, 'changedLevers').mockReturnValue(changedLeversData);

    jest.mock('app/caseDistribution/utils', () => ({
      ...jest.requireActual('app/caseDistribution/utils'),
      findOption: jest.fn(() => {
        return {
          item: 'text',
          backendValue: '10',
          value: '12',
          text: 'Option 1',
          data_type: 'number'
        };
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
      expect(document.querySelector(`#${leverData.item}-new-value`)).toHaveTextContent(leverData.options[0].text);
    }
  });

  it('closes the modal when cancel button is clicked', async () => {
    const store = getStore();

    const setShowModal = jest.fn();

    store.dispatch(loadLevers(changedLevers));
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
