import React from 'react';

import { HearingTypeConversionForm } from './HearingTypeConversionForm';

import { amaAppeal } from '../../../test/data/appeals';

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
    ...amaAppeal,
    closestRegionalOfficeLabel: "Nashville Regional office",
    powerOfAttorney: {
      representative_type: 'Service Organization',
      representative_name: "MASSACHUSETTS DEPARTMENT OF VETERANS' SERVICES"
    }
  },
  type: "Virtual"
}

export const Appellant = Template.bind({});
Appellant.args = {
  ...Basic.args,
  appeal: {
    ...Basic.args.appeal,
    appellantIsNotVeteran: true
  }
}

export const CentralOffice = Template.bind({});
CentralOffice.args = {
  ...Basic.args,
  appeal: {
    ...Basic.args.appeal,
    closestRegionalOfficeLabel: "Central Office"
  }
}
