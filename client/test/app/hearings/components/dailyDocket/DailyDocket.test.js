import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import DailyDocket from '../../../../../../client/app/hearings/components/dailyDocket/DailyDocket';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

const createReducer = (storeValues) => {
  return function(state = storeValues) {
    return state;
  };
};

it('does render judge name when judge first name and last name are present', async () => {
  const mockProps = {
    user: { userVsoEmployee: false },
    dailyDocket: { judgeFirstName: 'Jon', judgeLastName: 'Doe' },
  };

  const yourReducer = createReducer({
    components: {
    },
  });

  const store = createStore(yourReducer, compose(applyMiddleware(thunk)));

  render(
    <Provider store={store}>
      <Router>
        <DailyDocket {...mockProps} />
      </Router>
    </Provider>
  );
  expect(await screen.findByText(/VLJ:/)).toBeInTheDocument();
});

it('does not render judge name when judge first name and last name are null', async () => {
  const mockProps = {
    user: { userVsoEmployee: false },
    dailyDocket: { judgeFirstName: null, judgeLastName: null },
  };

  const yourReducer = createReducer({
    components: {
    },
  });

  const store = createStore(yourReducer, compose(applyMiddleware(thunk)));

  render(
    <Provider store={store}>
      <Router>
        <DailyDocket {...mockProps} />
      </Router>
    </Provider>
  );
  expect(await screen.queryByText(/VLJ:/)).not.toBeInTheDocument();
});

it('does not render judge name when userVsoEmployee is true and judge first name and last name are present',
  async () => {
    const mockProps = {
      user: { userVsoEmployee: true },
      dailyDocket: { judgeFirstName: 'Jon', judgeLastName: 'Doe' },
    };

    const yourReducer = createReducer({
      components: {
      },
    });

    const store = createStore(yourReducer, compose(applyMiddleware(thunk)));

    render(
      <Provider store={store}>
        <Router>
          <DailyDocket {...mockProps} />
        </Router>
      </Provider>
    );
    expect(await screen.queryByText(/VLJ:\s*Jon\s*Doe/)).not.toBeInTheDocument();
  });
