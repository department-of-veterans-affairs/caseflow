import React, { useState, useContext } from 'react';
import { date, text, boolean } from '@storybook/addon-knobs';
import { addDecorator } from '@storybook/react';

import { HearingConversion } from './HearingConversion';
import {
  updateHearingDispatcher,
  HearingsFormContext,
  HearingsFormContextProvider
} from '../contexts/HearingsFormContext';
import ReduxBase from '../../components/ReduxBase';
import reducers from '../reducers/index';
import { amaHearing } from '../../../test/data/hearings';

export default {
  title: 'Hearings/Components/HearingConversion',
  component: HearingConversion,
};

const Wrapped = () => {
  const { state: { hearing }, dispatch } = useContext(HearingsFormContext);

  const updateHearing = updateHearingDispatcher(hearing, dispatch);

  return (
    <HearingConversion
      update={updateHearing}
      hearing={hearing}
      type="change_to_virtual"
      scheduledFor={text('Scheduled For', '2020-06-01T21:23:17+0000', 'knobs')}
      errors={{}}
    />
  );
};

export const Normal = () => {
  return (
    <ReduxBase store={{}} reducer={reducers}>
      <HearingsFormContextProvider hearing={amaHearing}>
        <Wrapped />
      </HearingsFormContextProvider>
    </ReduxBase>
  );
};
