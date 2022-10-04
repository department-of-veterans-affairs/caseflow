import React, { useContext } from 'react';

import { VirtualHearingFields } from './VirtualHearingFields';
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
  component: VirtualHearingFields,
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
    <VirtualHearingFields
      update={updateHearing}
      hearing={hearing}
      {...props}
    />
  );
};

export const Normal = () => {
  return <Wrapper />;
};
