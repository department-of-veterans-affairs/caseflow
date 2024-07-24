import React from 'react';
import '@testing-library/jest-dom';

import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import ApiUtil from '../../../../../app/util/ApiUtil';
import thunk from 'redux-thunk';
import { transcriptionContractors } from '../../../../data/transcriptionContractors';

import TranscriptionSettings from
  '../../../../../app/hearings/components/transcriptionProcessing/TranscriptionSettings';

jest.mock('../../../../../app/util/ApiUtil');

const createStoreWithReducer = (initialState) => {
  const reducer = (state = initialState) => state;

  return createStore(reducer, compose(applyMiddleware(thunk)));
};

const renderTranscriptionSettings = () => {
  const store = createStoreWithReducer({ components: {} });

  return render(
    <Provider store={store}>
      <Router>
        <TranscriptionSettings contractors={transcriptionContractors} />
      </Router>
    </Provider>
  );
};

it('does render transcription settings information', async () => {
  ApiUtil.get.mockResolvedValue({
    body: {
      transcription_contractors: transcriptionContractors,
    },
  });

  const component = renderTranscriptionSettings();

  expect(component).toMatchSnapshot();
});

describe('work assignment toggle', () => {
  it('should be set to ON for first contractor', () => {
    const { container } = renderTranscriptionSettings();
    const toggles = container.querySelectorAll('.toggleButtonText');

    expect(toggles[0].textContent).toBe('On');
    expect(toggles[1].textContent).toBe('Off');
    expect(toggles[2].textContent).toBe('Off');
  });

  it('should be toggleable', () => {
    const contractor = transcriptionContractors[0];

    ApiUtil.patch.mockResolvedValue({
      body: {
        transcription_contractor: {
          ...contractor,
          is_available_for_work: !contractor.is_available_for_work
        }
      }
    });
    const { container } = renderTranscriptionSettings();
    const toggles = container.querySelectorAll('.toggleButtonText');

    fireEvent.click(toggles[0], () => {
      expect(toggles[0].textContent).toBe('Off');
    });

    fireEvent.click(toggles[0], () => {
      expect(toggles[0].textContent).toBe('On');
    });

    fireEvent.click(toggles[1], () => {
      expect(toggles[0].textContent).toBe('On');
      expect(toggles[1].textContent).toBe('On');
      expect(toggles[2].textContent).toBe('Off');
    });
  });
});

describe('weekly transcription count calculations', () => {
  it('give correct values', () => {
    renderTranscriptionSettings();
    expect(screen.getByText('7 of 150')).toBeInTheDocument();
    expect(screen.getByText('0 of 0')).toBeInTheDocument();
    expect(screen.getByText('2 of 120')).toBeInTheDocument();
  });
});
