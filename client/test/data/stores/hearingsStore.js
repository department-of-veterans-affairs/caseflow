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

