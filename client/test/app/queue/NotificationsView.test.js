import React from 'react';
import { render } from '@testing-library/react';
import { NotificationsView } from 'app/queue/NotificationsView';
import {
  BrowserRouter as Router,
} from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import { axe } from 'jest-axe';
import ApiUtil from '../../../app/util/ApiUtil';

const createSpyGet = (data) => {
  return jest.spyOn(ApiUtil, 'get').
    mockImplementation(() => new Promise((resolve) => resolve({ body: data })));
};

beforeEach(() => {
  createSpyGet([]);
});

afterEach(() => {
  jest.clearAllMocks();
});

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
  veteranParticipantId: '826209',
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
    const { container } = setup(state);
    const header = container.querySelector('h1').innerHTML;

    expect(header).toBe('Case notifications for Bob Smithschumm');
  });

  it('renders description correctly', () => {
    const { container } = setup(state);
    const description = container.querySelector('.notification-text').innerHTML;

    expect(description).toBe('VA Notify sent these status notifications to the Appellant about their case.');
  });

  it('renders download button', () => {
    const { container } = setup(state);
    const downloadButton = container.querySelector('#download-button');
    const downloadButtonText = container.querySelector('#download-button').innerHTML;

    expect(downloadButton).toBeInTheDocument();
    expect(downloadButtonText).toBe('Download');
  });


  it('matches snapshot', () => {
    const { container } = setup(state);

    expect(container).toMatchSnapshot();
  });

  it('Virtual passes ally testing', async () => {
    const { container } = setup(state);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
