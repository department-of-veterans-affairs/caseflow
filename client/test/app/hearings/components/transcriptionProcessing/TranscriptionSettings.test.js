import React from 'react';
import '@testing-library/jest-dom';

import { render, screen } from '@testing-library/react';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

import TranscriptionSettings from '../../../../../app/hearings/components/transcriptionProcessing/TranscriptionSettings';

const createStoreWithReducer = (initialState) => {
  const reducer = (state = initialState) => state;

  return createStore(reducer, compose(applyMiddleware(thunk)));
};

const renderTranscriptionSettings = () => {
  const store = createStoreWithReducer({ components: {} });

  return render(
    <Provider store={store}>
      <Router>
        < TranscriptionSettings />
      </Router>
    </Provider>
  );
};

it('does render transcription settings information', async () => {
  renderTranscriptionSettings();

  expect(await screen.findByText(/Transcription Settings/)).toBeInTheDocument();
  expect(await screen.findByText(/Edit Current Contractors/)).toBeInTheDocument();

  expect(await screen.findByText(/Link to box.com:/)).toBeInTheDocument();
  expect(await screen.findByText(/POC:/)).toBeInTheDocument();
  expect(await screen.findByText(/Hearings sent to Contractor A this week:/)).toBeInTheDocument();
});
