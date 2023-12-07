import React from 'react';
import { render, screen } from '@testing-library/react';
import LastRetrievalAlert from '../../../app/reader/LastRetrievalAlert';
import { alertMessage, warningMessage } from '../constants/LastRetrievalAlert'
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import documentListReducer from '../../../app/reader/DocumentList/DocumentListReducer'

describe('LastRetrievalAlert', () => {
  const setup = (date = null) => {
    const store = createStore(documentListReducer, applyMiddleware(thunk));

    return render(
      <Provider store={store}>
        <LastRetrievalAlert
          appeal={{veteran_full_name: "John Doe"}}
          manifestVbmsFetchedAt={date}
        />
      </Provider>
    );
  };


  it('does not render alert or warning message when eFolder document has been fetched and now is null', () => {
    setup('05/10/23 10:34am EDT -0400');

    expect(screen.queryByText(alertMessage, { exact: false })).toBeFalsy();
    expect(screen.queryByText(warningMessage)).toBeFalsy();
  });

  it('renders alert message when eFolder Document has not been fetched', () => {
    setup();

    expect(screen.getByText(alertMessage, { exact: false })).toBeTruthy();
    expect(screen.queryByText(warningMessage)).toBeFalsy();
  });

  it('renders warning message when now is returned', () => {
    Date.now = jest.fn(() => new Date("2023-05-11T12:40:00.000Z"));

    setup('05/10/23 10:34am EDT -0400');

    expect(screen.queryByText(alertMessage)).toBeFalsy();
    expect(screen.getByText(warningMessage, { exact: false })).toBeTruthy();
  });
});
