import React from 'react';
import { useArgs } from '@storybook/client-api';

import { defaultHearing, virtualHearing, centralHearing } from '../../../test/data/hearings';
import { amaAppeal, scheduleHearingDetails } from '../../../test/data/appeals';
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
  appellantTitle: 'Veteran',
  appeal: amaAppeal,
  hearing: {
    ...defaultHearing,
    requestType: defaultHearing.readableRequestType
  },
};

const Template = (args) => {
  return (
    <Wrapper>
      <ScheduleVeteranForm
        {...defaultArgs}
        {...args}
        onChange={() => console.log('Changed')}
      />
    </Wrapper>

  );
};

export const Default = Template.bind({});

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
    hearingLocation: scheduleHearingDetails.hearingLocation
  },
  virtual: true
};

export const CentralToVirtualConversion = Template.bind({});
CentralToVirtualConversion.args = {
  virtual: true,
  hearing: {
    ...centralHearing,
    requestType: centralHearing.readableRequestType,
  },
};

export const VideoWithErrors = Template.bind({});
VideoWithErrors.args = {
  hearing: {
    ...defaultHearing,
    requestType: defaultHearing.readableRequestType,
  },
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

export const VirtualWithErrors = Template.bind({});
VirtualWithErrors.args = {
  virtual: true,
  hearing: {
    ...defaultHearing,
    requestType: defaultHearing.readableRequestType,
    virtualHearing: virtualHearing.virtualHearing
  },
  appeal: {
    ...amaAppeal,
    regionalOffice: defaultHearing.regionalOfficeKey
  },
  errors: {
    hearingDay: 'Cannot find hearing day',
    scheduledTimeString: 'Invalid time selected',
    appellantEmail: 'Invalid appellant email',
    representativeEmail: 'Invalid representative email'
  }
};
