import React from 'react';

import { amaAppeal, powerOfAttorney } from '../../../../test/data/appeals';

import { LEGACY_APPEAL_TYPES } from '../../../queue/constants';
import { AppealInformation } from './AppealInformation';

export default {
  title: 'Hearings/Components/Schedule Hearing/AppealInformation',
  component: AppealInformation,
  argTypes: {
    appeal: { table: { disable: true } },
  }
};

const Template = (args) => {
  return (
    <AppealInformation
      {...args}
      appeal={{
        ...amaAppeal,
        appellantIsNotVeteran: args.appellantIsNotVeteran,
        issueCount: args.issueCount,
        caseType: args.caseType,
        isAdvancedOnDocket: args.isAdvancedOnDocket,
        docketName: args.docketName,
        docketNumber: args.docketNumber,
        powerOfAttorney: {
          ...amaAppeal.powerOfAttorney,
          representative_name: args.representative_name,
        },
        veteranDateOfDeath: args.veteranDateOfDeath,
      }}
    />
  );
};

export const Basic = Template.bind({});
Basic.args = {
  appellantIsNotVeteran: amaAppeal.appellantIsNotVeteran,
  issueCount: amaAppeal.issueCount,
  caseType: amaAppeal.caseType,
  isAdvancedOnDocket: amaAppeal.isAdvancedOnDocket,
  docketName: amaAppeal.docketName,
  docketNumber: amaAppeal.docketNumber,
  representative_name: powerOfAttorney.representative_name,
  veteranDateOfDeath: null
};
Basic.argTypes = {
  issueCount: { control: { type: 'number' } },
  caseType: { control: { type: 'select', options: ['Original', LEGACY_APPEAL_TYPES.CAVC_REMAND] } },
  docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
  veteranDateOfDeath: { control: { type: 'date' } }
};
