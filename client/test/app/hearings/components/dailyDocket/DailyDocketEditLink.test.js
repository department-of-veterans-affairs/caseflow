import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import DailyDocketEditLink from '../../../../../../client/app/hearings/components/dailyDocket/DailyDocketEditLinks';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

const createStoreWithReducer = (initialState) => {
  const reducer = (state = initialState) => state;

  return createStore(reducer, compose(applyMiddleware(thunk)));
};

const renderDailyDocket = (props) => {
  const store = createStoreWithReducer({ components: {} });

  return render(
    <Provider store={store}>
      <Router>
        <DailyDocketEditLink {...props} />
      </Router>
    </Provider>
  );
};

it('does render docket notes when user is a board employee', async () => {
  const mockProps = {
    user: { userIsBoardEmployee: true },
    dailyDocket: { notes: 'There is a note here' },
  };

  renderDailyDocket(mockProps);
  expect(await screen.findByText(/Notes:/)).toBeInTheDocument();
});

it('does not render docket notes when user is a nonBoardEmployee', async () => {
  const mockProps = {
    user: { userIsBoardEmployee: false },
    dailyDocket: { notes: 'There is a note here' },
  };

  renderDailyDocket(mockProps);
  expect(await screen.queryByText(/Note:\s*This\s*is\s*a\s*note/)).not.toBeInTheDocument();
});
