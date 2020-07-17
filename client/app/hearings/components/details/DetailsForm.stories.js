import React, { useContext } from 'react';
import { date } from '@storybook/addon-knobs';

import DetailsForm from './DetailsForm';
import {
  updateHearingDispatcher,
  HearingsFormContext,
  HearingsFormContextProvider
} from '../../contexts/HearingsFormContext';
import ReduxBase from '../../../components/ReduxBase';
import reducers from '../../reducers/index';
import { amaHearing } from '../../../../test/data/hearings';

export default {
  title: 'Hearings/Components/Hearing Details/DetailsForm',
  component: DetailsForm,
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
    <DetailsForm
      update={updateHearing}
      hearing={hearing}
      type="change_to_virtual"
      scheduledFor={date('Scheduled For', new Date(), 'knobs')}
      {...props}
    />
  );
};

export const Normal = () => {

  return <Wrapper />;
};
