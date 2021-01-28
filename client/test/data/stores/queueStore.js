import { omit } from 'lodash';
import React from 'react';
import { createStore } from 'redux';
import { Provider } from 'react-redux';
import { MemoryRouter, Route } from 'react-router-dom';

import reducer from '../../../app/queue/reducers';
import { defaultHearing, hearingDateOptions } from '../../data/hearings';
import { amaAppeal, openHearingAppeal, defaultAssignHearing, legacyAppeal } from '../../data/appeals';
import { roLocations, roList } from '../../data/regional-offices';

export const appealsData = {
  [legacyAppeal.externalId]: legacyAppeal,
  [amaAppeal.externalId]: amaAppeal,
  [openHearingAppeal.externalId]: openHearingAppeal,
};

export const initialState = {
  components: {
    scheduledHearing: {
      taskId: null,
      disposition: null,
      externalId: null,
      polling: false,
    },
    dropdowns: {
      regionalOffices: { options: roList },
      [`hearingLocationsFor${amaAppeal.externalId}At${defaultHearing.regionalOfficeKey}`]: { options: roLocations },
      [`hearingDatesFor${defaultHearing.regionalOfficeKey}`]: { options: hearingDateOptions }
    },
    forms: {
      assignHearing: defaultAssignHearing
    }
  },
  queue: {
    appeals: appealsData,
    appealDetails: appealsData,
    stagedChanges: {
      appeals: {}
    }
  },
  ui: {
    messages: {},
    saveState: {},
    modals: {},
    featureToggles: {}
  }
};

export const queueWrapper = ({ children, ...props }) => {
  // Providing `route` allows tests that depend on a route match to work (in
  // other words, if your component relies on `prop.match`).
  const initialRoute = props.route;

  return (
    <Provider store={createStore(reducer, {
      ...initialState,
      ...omit(props, ['route']),
      components: {
        ...initialState.components,
        ...props?.components,
        dropdowns: {
          ...initialState.components.dropdowns,
          ...props?.components?.dropdowns,
        },
        forms: {
          ...initialState.components.forms,
          ...props?.components?.forms,
        },
        scheduledHearing: {
          ...initialState.components.scheduledHearing,
          ...props?.components?.scheduledHearing,
        }
      },
      queue: {
        ...initialState.queue,
        ...props?.queue
      },
      ui: {
        ...initialState.ui,
        ...props?.ui
      },
    })}>
      <MemoryRouter
        initialEntries={initialRoute ? [initialRoute] : ['/']}
        keyLength={0}
      >
        {/* Create a dummy route for the supplied route. */}
        {initialRoute && <Route path={initialRoute}>{children}</Route>}
        {/* No route supplied. */}
        {!initialRoute && <React.Fragment>{children}</React.Fragment>}
      </MemoryRouter>
    </Provider>
  );
};

