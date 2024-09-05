import React, { useContext } from 'react';
import { date, select, object, radios, boolean } from '@storybook/addon-knobs';

import { HearingConversion } from './HearingConversion';
import {
  updateHearingDispatcher,
  HearingsFormContext,
  HearingsFormContextProvider,
} from '../contexts/HearingsFormContext';
import ReduxBase from '../../components/ReduxBase';
import reducers from '../reducers/index';
import { amaHearing } from '../../../test/data/hearings';
import { HEARING_CONVERSION_TYPES } from '../constants';
import { hearingTimeOptsWithZone } from '../utils';
import HEARING_TIME_OPTIONS from '../../../constants/HEARING_TIME_OPTIONS';

export default {
  title: 'Hearings/Components/HearingConversion',
  component: HearingConversion,
};

const Wrapper = (props) => {
  return (
    <ReduxBase store={{}} reducer={reducers}>
      <HearingsFormContextProvider hearing={amaHearing}>
        <Wrapped {...props} />
      </HearingsFormContextProvider>
    </ReduxBase>
  );
};

const Wrapped = (props) => {
  const {
    state: { hearing },
    dispatch,
  } = useContext(HearingsFormContext);

  const updateHearing = updateHearingDispatcher(hearing, dispatch);

  return (
    <HearingConversion
      hearing={props.hearing}
      title="Convert"
      update={updateHearing}
      type={props.type}
      scheduledFor={props.scheduledFor || hearing.scheduledFor}
      updateCheckboxes={() => 'A checkbox has been checked'}
      userVsoEmployee={props.userVsoEmployee}
      {...props}
    />
  );
};

export const Normal = () => {
  const dateTime = (name, defaultValue) => {
    const stringTimestamp = date(name, defaultValue, 'knobs');

    return new Date(stringTimestamp);
  };
  const init = new Date('2020-06-01T21:23:17+0000');
  const controlledHearing = (value) => {
    return {
      ...value,
      scheduledTimeString: select('Time', hearingTimeOptsWithZone(HEARING_TIME_OPTIONS), '08:15', 'knobs'),
    };
  };

  return (
    <Wrapper
      type={radios('Type', HEARING_CONVERSION_TYPES.slice(0, 2), HEARING_CONVERSION_TYPES[0], 'knobs')}
      scheduledFor={dateTime('Scheduled For', init)}
      hearing={controlledHearing(amaHearing)}
    />
  );
};

export const ConvertToVirtual = () => {
  return <Wrapper hearing={amaHearing} type={HEARING_CONVERSION_TYPES[0]} />;
};

export const ConvertToVirtualAsVSO = () => {
  return <Wrapper
    hearing={amaHearing}
    type={HEARING_CONVERSION_TYPES[0]}
    setIsNotValidEmail={() => 'Email Changed'}
    userVsoEmployee
  />;
};

export const ConvertFromVirtual = () => {
  return <Wrapper hearing={amaHearing} type={HEARING_CONVERSION_TYPES[1]} />;
};
