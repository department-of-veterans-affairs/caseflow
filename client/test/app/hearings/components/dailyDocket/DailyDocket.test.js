import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import DailyDocket from '../../../../../../client/app/hearings/components/dailyDocket/DailyDocket';
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
        <DailyDocket {...props} />
      </Router>
    </Provider>
  );
};

it('does render judge name when user is a Board employee', async () => {
  const mockProps = {
    user: { userIsBoardHearingsEmployee: true },
    dailyDocket: { judgeFirstName: 'Jon', judgeLastName: 'Doe' },
  };

  renderDailyDocket(mockProps);
  expect(await screen.findByText(/VLJ:/)).toBeInTheDocument();
});

it('does not render judge name when userVsoEmployee is true and judge first name and last name are present',
  async () => {
    const mockProps = {
      user: { userIsBoardHearingsEmployee: false },
      dailyDocket: { judgeFirstName: 'Jon', judgeLastName: 'Doe' },
    };

    renderDailyDocket(mockProps);
    expect(await screen.queryByText(/VLJ:\s*Jon\s*Doe/)).not.toBeInTheDocument();
  });
