import React, { useState } from 'react';
import { date, text, boolean } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import { BrowserRouter, Switch } from 'react-router-dom';

import Details from './Details';
import {
  updateHearingDispatcher,
  HearingsFormContext,
  HearingsFormContextProvider,
} from '../contexts/HearingsFormContext';
import { HearingsUserContext } from '../contexts/HearingsUserContext';
import ReduxBase from '../../components/ReduxBase';
import reducers from '../reducers/index';
import { amaHearing } from '../../../test/data/hearings';
import { userWithVirtualHearingsFeatureEnabled } from '../../../test/data/user';

export default {
  title: 'Hearings/Components/Details',
  component: Details,
};

const Wrapped = ({ children }) => {
  return (
    <BrowserRouter basename="/hearings">
      <ReduxBase store={{}} reducer={reducers}>
        <HearingsUserContext.Provider
          value={userWithVirtualHearingsFeatureEnabled}
        >
          <HearingsFormContextProvider hearing={amaHearing}>
            {children}
          </HearingsFormContextProvider>
        </HearingsUserContext.Provider>
      </ReduxBase>
    </BrowserRouter>
  );
};

export const Normal = () => {
  return (
    <Wrapped>
      <Details
        hearing={amaHearing}
        saveHearing={(e) => action('save')(e.target)}
        goBack={(e) => action('save')(e.target)}
        onReceiveAlerts={(e) => action('save')(e.target)}
        onReceiveTransitioningAlert={(e) => action('save')(e.target)}
        transitionAlert={(e) => action('save')(e.target)}
      />
    </Wrapped>
  );
};
