import React from 'react';
import { createStore } from 'redux';
import { Provider } from 'react-redux';
import { BrowserRouter as Router } from 'react-router-dom';

import { HearingsFormContextProvider } from '../../../app/hearings/contexts/HearingsFormContext';
import { HearingsUserContext } from '../../../app/hearings/contexts/HearingsUserContext';
import reducer from '../../../app/hearings/reducers';
import { defaultHearing, amaHearing, centralHearing } from '../hearings';

export const initialState = {
  hearingSchedule: { hearings: [defaultHearing, amaHearing, centralHearing] },
  dailyDocket: {
    hearingDay: {
      conferenceLink: {
        0: {
          hostPin: '2949749',
          hostLink: 'https://example.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA0000031@example.va.gov&pin=2949749&role=host',
          alias: 'BVA0000130@example.va.gov',
          guestPin: '9523850278',
          guestLink: 'https://example.va.gov/sample/?conference=BVA0000130@example.va.gov&pin=9523850278&callType=video',
          coHostLink: null,
          type: 'PexipConferenceLink',
          conferenceProvider: 'pexip'
        }
      }
    }
  },
  components: {
    dropdowns: {
      hearingCoordinators: {
        isFetching: false,
        options: []
      }
    }
  }
};

export const detailsStore = createStore(
  reducer,
  initialState
);

export const hearingDetailsWrapper = (user, hearing) => ({ children }) => (
  <Provider store={detailsStore}>
    <Router>
      <HearingsUserContext.Provider value={user}>
        <HearingsFormContextProvider hearing={hearing}>
          {children}
        </HearingsFormContextProvider>
      </HearingsUserContext.Provider>
    </Router>
  </Provider>
);

