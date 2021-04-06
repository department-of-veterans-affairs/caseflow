import React from 'react';

import { amaAppeal, powerOfAttorney } from '../../../../test/data/appeals';

import { LEGACY_APPEAL_TYPES } from '../../../queue/constants';
import { AssignHearingsList } from './AssignHearingsList';

export default {
  title: 'Hearings/Components/Schedule Hearing/AssignHearingsList',
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
};
Basic.argTypes = {
  issueCount: { control: { type: 'number' } },
  caseType: { control: { type: 'select', options: ['Original', LEGACY_APPEAL_TYPES.CAVC_REMAND] } },
  docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
  veteranDateOfDeath: { control: { type: 'date' } }
};
