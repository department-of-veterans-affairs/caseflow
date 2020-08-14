import React from 'react';
import { useArgs } from '@storybook/client-api';

import { defaultHearing } from '../../../test/data/hearings';
import { amaAppeal, scheduleHearingDetails } from '../../../test/data/appeals';
import { ScheduleVeteran } from './ScheduleVeteran';
import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';

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
    <Wrapper>
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
    </Wrapper>

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

export const VideoToVirtualConversion = Template.bind({});
VideoToVirtualConversion.args = {
  appeal: {
    ...amaAppeal,
    regionalOffice: defaultHearing.regionalOfficeKey,
    hearingLocation: scheduleHearingDetails.hearingLocation }
};

export const WithErrors = Template.bind({});
WithErrors.args = {
  appeal: {
    ...amaAppeal,
    regionalOffice: defaultHearing.regionalOfficeKey
  },
  errors: {
    hearingLocation: 'Unknown Hearing Location',
    hearingDay: 'Cannot find hearing day',
    scheduledTimeString: 'Invalid time selected',
  }
};
