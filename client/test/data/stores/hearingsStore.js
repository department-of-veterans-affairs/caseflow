import React from 'react';
import { createStore } from 'redux';
import { Provider } from 'react-redux';
import { BrowserRouter as Router } from 'react-router-dom';

import { HearingsFormContextProvider } from '../../../app/hearings/contexts/HearingsFormContext';
import { HearingsUserContext } from '../../../app/hearings/contexts/HearingsUserContext';
import reducer from '../../../app/hearings/reducers';

export const detailsStore = createStore(
  reducer,
  {
    components: {
      dropdowns: {
        hearingCoordinators: {
          isFetching: false,
          options: []
        }
      }
    }
  }
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

