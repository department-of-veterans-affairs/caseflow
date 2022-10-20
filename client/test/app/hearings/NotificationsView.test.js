import React from 'react';
import { render, screen } from '@testing-library/react';
import { NotificationsView } from 'app/queue/NotificationsView';
import {
  BrowserRouter as Router,
} from "react-router-dom";
import { Provider } from 'react-redux';
import { createStore } from 'redux';

const createReducer = (storeValues) => {
  return function (state = storeValues) {

    return state;
  };
};

const setup = (state) => {
  const reducer = createReducer(state);
  const props = {
    appealId: 'e1bdff31-4268-4fd4-a157-ebbd48013d91',
    attr: 'dedfsd',
    attr2: 'qrdfds'
  };

  const store = createStore(reducer);

  return render(
    <Provider store={store} >
      <Router>
        <NotificationsView {...props} />
      </Router>
    </Provider>
  );
};
const appeal = {
  id: '1987',
  isLegacyAppeal: false,
  docketNumber: '220715-1987',
  veteranFullName: 'Bob Smithschumm',
  veteranFileNumber: '200000161',
  hearings: [],
};

const state = {
  queue: {
    appealId: 'e1bdff31-4268-4fd4-a157-ebbd48013d91',
    appeals: { 'e1bdff31-4268-4fd4-a157-ebbd48013d91': appeal },
    mostRecentlyHeldHearingForAppeal: {}

  },
  appealId: 'e1bdff31-4268-4fd4-a157-ebbd48013d91',
  ui: {
    organizations: [{ name: 'Hearings Management', url: 'hearings-management' }],
    featureToggles: {
      overtime_revamp: false
    }
  },
};

describe('NotificationsTest', () => {


  it('renders title correctly', () => {

    const {container} = setup(state);
    const header = container.querySelector('h1').innerHTML
    expect(header).toBe('Case notifications for Bob Smithschumm')
  
  });

});

