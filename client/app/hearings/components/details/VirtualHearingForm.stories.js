import React, { useState, useContext } from 'react';
import { date, text, boolean } from '@storybook/addon-knobs';
import { addDecorator } from '@storybook/react';

import { VirtualHearingForm } from './VirtualHearingForm';
import {
  updateHearingDispatcher,
  HearingsFormContext,
  HearingsFormContextProvider
} from '../../contexts/HearingsFormContext';
import ReduxBase from '../../../components/ReduxBase';
import reducers from '../../reducers/index';
import { amaHearing } from '../../../../test/data/hearings';

export default {
  title: 'Hearings/Components/Hearing Details/VirtualHearingForm',
  component: VirtualHearingForm,
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
  const { state: { hearing }, dispatch } = useContext(HearingsFormContext);

  const updateHearing = updateHearingDispatcher(hearing, dispatch);

  return (
    <VirtualHearingForm
      update={updateHearing}
      hearing={hearing}
      {...props}
    />
  );
};

export const Normal = () => {
  return <Wrapper />;
};
