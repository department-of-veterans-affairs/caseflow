import React from 'react';

import { VSOHearingTypeConversionForm } from './VSOHearingTypeConversionForm';
import { HearingTypeConversionProvider } from '../contexts/HearingTypeConversionContext';

import { legacyAppealForTravelBoard, veteranInfoWithoutEmail, virtualAppeal } from '../../../test/data/appeals';

export default {
  title: 'Hearings/Components/VSOHearingTypeConversionForm',
  component: VSOHearingTypeConversionForm,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  }
};

const Template = (args) => (
  <HearingTypeConversionProvider initialAppeal={args.appeal}>
    <VSOHearingTypeConversionForm {...args} />
  </HearingTypeConversionProvider>
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

export const VirtualVSOAppeal = Template.bind({});
VirtualVSOAppeal.args = {
  appeal: {
    ...virtualAppeal
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
