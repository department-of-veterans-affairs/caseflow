import React from 'react';
import { useArgs } from '@storybook/client-api';

import queueReducer, { initialState } from '../../queue/reducers';
import ReduxBase from '../../components/ReduxBase';
import { defaultHearing, hearingDateOptions } from '../../../test/data/hearings';
import { amaAppeal } from '../../../test/data/appeals';
import { ScheduleVeteran } from './ScheduleVeteran';
import { roList, roLocations } from '../../../test/data/regional-offices';

export default {
  title: 'Hearings/Components/ScheduleVeteran',
  component: ScheduleVeteran,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  },
  argTypes: {
  }
};

const defaultArgs = {
  appeal: amaAppeal,
  hearing: defaultHearing,
};

const Template = (args) => {
  const [storyArgs, updateStoryArgs] = useArgs();
  const handleChange = (key, value) => {
    updateStoryArgs({
      ...defaultArgs,
      ...storyArgs,
      [key]: {
        ...defaultArgs[key],
        ...storyArgs[key],
        ...value
      }
    });
  };

  return (
    <ReduxBase reducer={queueReducer} initialState={{
      queue: { ...initialState },
      components: {
        dropdowns: {
          regionalOffices: { options: roList },
          [`hearingLocationsFor${amaAppeal.externalId}At${defaultHearing.regionalOfficeKey}`]: { options: roLocations },
          [`hearingDatesFor${defaultHearing.regionalOfficeKey}`]: { options: hearingDateOptions }
        }
      }
    }}>
      <ScheduleVeteran
        {...args}
        {...defaultArgs}
        {...storyArgs}
        onChange={handleChange}
        /* eslint-disable no-console */
        submit={() => console.log('Submitted')}
        goBack={() => console.log('Cancelled')}
        /* eslint-enable no-console */
      />
    </ReduxBase>

  );
};

export const Default = Template.bind({});

export const Loading = Template.bind({});
Loading.args = {
  loading: true
};

export const RegionalOfficeSelected = Template.bind({});
RegionalOfficeSelected.args = {
  appeal: {
    ...amaAppeal,
    regionalOffice: defaultHearing.regionalOfficeKey
  }
};
