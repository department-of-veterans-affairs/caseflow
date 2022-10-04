import React from 'react';

import { HearingTypeConversionForm } from './HearingTypeConversionForm';

import { legacyAppealForTravelBoard, veteranInfoWithoutEmail } from '../../../test/data/appeals';

export default {
  title: 'Hearings/Components/HearingTypeConversionForm',
  component: HearingTypeConversionForm,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  }
};

const Template = (args) => (
  <HearingTypeConversionForm {...args} />
);

export const Basic = Template.bind({});
Basic.args = {
  appeal: {
    ...legacyAppealForTravelBoard
  },
  type: 'Virtual'
};

export const Appellant = Template.bind({});
Appellant.args = {
  ...Basic.args,
  appeal: {
    ...Basic.args.appeal,
    appellantIsNotVeteran: true
  }
};

export const CentralOffice = Template.bind({});
CentralOffice.args = {
  ...Basic.args,
  appeal: {
    ...Basic.args.appeal,
    closestRegionalOfficeLabel: 'Central Office'
  }
};

export const MissingVeteranEmailAlert = Template.bind({});
MissingVeteranEmailAlert.args = {
  ...Basic.args,
  appeal: {
    ...Basic.args.appeal,
    veteranInfo: {
      ...veteranInfoWithoutEmail
    }
  }
};

export const AppealNotGeomatchedYet = Template.bind({});
AppealNotGeomatchedYet.args = {
  ...Basic.args,
  appeal: {
    ...legacyAppealForTravelBoard,
    closestRegionalOfficeLabel: null
  }
};
