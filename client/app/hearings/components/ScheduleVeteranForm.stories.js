import React from 'react';
import { useArgs } from '@storybook/client-api';

import { defaultHearing } from '../../../test/data/hearings';
import { amaAppeal } from '../../../test/data/appeals';
import { ScheduleVeteranForm } from './ScheduleVeteranForm';
import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';

export default {
  title: 'Hearings/Components/ScheduleVeteranForm',
  component: ScheduleVeteranForm,
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
      <ScheduleVeteranForm
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
