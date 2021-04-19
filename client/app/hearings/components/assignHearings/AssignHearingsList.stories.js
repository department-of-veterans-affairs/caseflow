import React from 'react';

import { AssignHearingsList } from './AssignHearingsList';
import { amaHearing, legacyHearing, defaultHearing } from '../../../../test/data/hearings';

export default {
  title: 'Hearings/Components/Assign Hearings/AssignHearingsList',
  component: AssignHearingsList,
  argTypes: {
    appeal: { table: { disable: true } },
  }
};

const Template = (args) => {
  return (
    <AssignHearingsList
      {...args}
    />
  );
};

export const Basic = Template.bind({});
Basic.args = {
  hearings: [defaultHearing, amaHearing, legacyHearing]
};
Basic.argTypes = {
};
