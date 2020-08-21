import React from 'react';
import { createStore } from 'redux';
import { Provider } from 'react-redux';
import { BrowserRouter as Router } from 'react-router-dom';

import reducer from '../../../app/queue/reducers';
import { defaultHearing, hearingDateOptions } from '../../data/hearings';
import { amaAppeal } from '../../data/appeals';
import { roLocations, roList } from '../../data/regional-offices';

export const initialState = {
  components: {
    dropdowns: {
      regionalOffices: { options: roList },
      [`hearingLocationsFor${amaAppeal.externalId}At${defaultHearing.regionalOfficeKey}`]: { options: roLocations },
      [`hearingDatesFor${defaultHearing.regionalOfficeKey}`]: { options: hearingDateOptions }
    }
  }
};

export const queueStore = createStore(
  reducer,
  initialState
);

export const queueWrapper = ({ children }) => (
  <Provider store={queueStore}>
    <Router>
      {children}
    </Router>
  </Provider>
);

