import React from 'react';
import { useArgs } from '@storybook/client-api';

import queueReducer, { initialState } from '../../queue/reducers';
import ReduxBase from '../../components/ReduxBase';
import { amaHearing } from '../../../test/data/hearings';
import { amaAppeal } from '../../../test/data/appeals';
import { ScheduleVeteran } from './ScheduleVeteran';
import { roList } from '../../../test/data/regional-offices';

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
    onChange: { action: 'onChange' },
    type: {
      control: { type: 'select', options: ['date', 'datetime-local', 'text'] },
    },
  }
};

const defaultArgs = {
  appeal: amaAppeal,
  hearing: amaHearing,
};

const Template = (args) => {
  const [storyArgs, updateStoryArgs] = useArgs();
  const handleChange = (value) => {
    args.onChange(value);
    updateStoryArgs({ ...storyArgs, value });
  };

  return (
    <ReduxBase reducer={queueReducer} initialState={{ queue: { ...initialState } }}>
      <ScheduleVeteran {...args} {...defaultArgs} onChange={handleChange} roList={roList} />
    </ReduxBase>

  );
};

export const Default = Template.bind({});
