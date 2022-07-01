import React, { useState, useContext } from 'react';
import { select, boolean, button } from '@storybook/addon-knobs';
import { action } from '@storybook/addon-actions';
import { BrowserRouter } from 'react-router-dom';

import Details from './Details';
import { HearingsFormContextProvider } from '../contexts/HearingsFormContext';
import { HearingsUserContext } from '../contexts/HearingsUserContext';
import ReduxBase from '../../components/ReduxBase';
import reducer from '../reducers';
import {
  virtualHearingEmails,
  amaHearing,
  centralHearing,
  defaultHearing,
  virtualHearing,
} from '../../../test/data/hearings';
import {
  vsoUser,
  nonVsoUser
} from '../../../test/data/user'
import { userWithVirtualHearingsFeatureEnabled } from '../../../test/data/user';
import { detailsStore, initialState } from '../../../test/data/stores/hearingsStore';

export default {
  title: 'Hearings/Components/Details',
  component: Details,
};

const Wrapper = (props) => {
  return (
    <BrowserRouter basename="/hearings">
      <ReduxBase initialState={initialState} store={detailsStore} reducer={reducer}>
        <HearingsUserContext.Provider
          value={props.user}
        >
          <HearingsFormContextProvider hearing={props.hearing}>
            <Wrapped hearing={props.hearing} {...props} />
          </HearingsFormContextProvider>
        </HearingsUserContext.Provider>

      </ReduxBase>
    </BrowserRouter>
  );
};

const Wrapped = (props) => {
  return (
    <Details
      hearing={props.hearing}
      saveHearing={(e) => action('save')(e.target)}
      goBack={(e) => action('save')(e.target)}
      onReceiveAlerts={(e) => action('save')(e.target)}
      onReceiveTransitioningAlert={(e) => action('save')(e.target)}
      transitionAlert={(e) => action('save')(e.target)}
    />
  );
};

export const Normal = () => {
  // Create a list of the options
  const selectedHearing = select(
    'hearing',
    { Video: defaultHearing, Central: centralHearing, Virtual: amaHearing },
    defaultHearing
  );

  // Create a state to force reading of knob props
  const [loaded, setLoad] = useState(true);
  const reload = () => {
    setLoad(false);
    setLoad(true);
  };

  // Set the virtual control
  const virtual = boolean('Was Virtual?', false);

  // Set the emails control
  const emails = boolean('Sent Emails?', false);

  // Add controls to the hearing
  const controlledHearing = {
    ...selectedHearing,
    ...(emails ? virtualHearingEmails : {}),
    ...(virtual ? virtualHearing : {}),
    scheduledForIsPast: boolean('Past Schedule?', false),
    wasVirtual: virtual,
    docketName: boolean('Legacy', false) ? 'rand' : 'hearing',
  };

  // Create a button to reload the hearing details
  button('Change Hearing', reload);

  return loaded && <Wrapper hearing={controlledHearing} user={nonVsoUser}/>;
};

export const Video = () => {
  return <Wrapper hearing={defaultHearing} user={nonVsoUser} />;
};

export const CentralOffice = () => {
  return <Wrapper hearing={centralHearing} user={nonVsoUser} />;
};

export const Virtual = () => {
  return <Wrapper hearing={amaHearing} user={nonVsoUser} />;
};

export const VirtualAsVSO = () =>{
  return <Wrapper hearing={amaHearing} user={vsoUser} />;
};

export const Legacy = () => {
  return (
    <Wrapper
      hearing={{
        ...defaultHearing,
        docketName: 'rand',
      }}
      user={nonVsoUser}
    />
  );
};
