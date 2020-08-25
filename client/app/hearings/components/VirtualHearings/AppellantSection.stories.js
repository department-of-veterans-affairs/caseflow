import React from 'react';
import { useArgs } from '@storybook/client-api';

import { virtualHearing, defaultHearing } from '../../../../test/data/hearings';
import { AppellantSection } from './AppellantSection';
import { HEARING_CONVERSION_TYPES } from '../../constants';

export default {
  title: 'Hearings/Components/Virtual Hearings/AppellantSection',
  component: AppellantSection,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 360,
      iframeWidth: 360,
    },
  },
  argTypes: {
    appellantTitle: {
      control: { type: 'select', options: ['Appellant', 'Veteran'] },
      defaultValue: ['Appellant']
    },
  }
};

const defaultArgs = {
  virtualHearing: virtualHearing.virtualHearing,
  hearing: defaultHearing,
  type: HEARING_CONVERSION_TYPES[0],
  virtual: false,
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
    <div>
      <AppellantSection
        {...args}
        {...defaultArgs}
        {...storyArgs}
        update={handleChange}
      />
    </div>

  );
};

export const Default = Template.bind({});

export const VirtualHearing = Template.bind({});
VirtualHearing.args = {
  virtual: true
};

export const ReadOnly = Template.bind({});
ReadOnly.args = {
  readOnly: true
};
