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
  hearing: defaultHearing,
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
  hearing: {
    ...defaultHearing,
    regionalOffice: defaultHearing.regionalOfficeKey,
  }
};

export const VideoToVirtualConversion = Template.bind({});
VideoToVirtualConversion.args = {
  appeal: {
    ...amaAppeal,
    hearingLocation: scheduleHearingDetails.hearingLocation
  },
  hearing: {
    ...defaultHearing,
    regionalOffice: defaultHearing.regionalOfficeKey,
  },
  virtual: true
};

export const CentralToVirtualConversion = Template.bind({});
CentralToVirtualConversion.args = {
  virtual: true,
  hearing: {
    ...centralHearing,
    regionalOffice: centralHearing.regionalOfficeKey,
  }
};

export const VideoWithErrors = Template.bind({});
VideoWithErrors.args = {
  hearing: {
    ...defaultHearing,
    regionalOffice: defaultHearing.regionalOfficeKey,
  },
  appeal: amaAppeal,
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
    regionalOffice: defaultHearing.regionalOfficeKey,
    virtualHearing: virtualHearing.virtualHearing
  },
  appeal: amaAppeal,
  errors: {
    hearingDay: 'Cannot find hearing day',
    scheduledTimeString: 'Invalid time selected',
    appellantEmail: 'Invalid appellant email',
    representativeEmail: 'Invalid representative email'
  }
};
