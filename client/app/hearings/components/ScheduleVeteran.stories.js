import React from 'react';

import { defaultHearing, virtualHearing, hearingDateOptions } from '../../../test/data/hearings';
import { amaAppeal, openHearingAppeal, defaultAssignHearing, scheduleHearingDetails } from '../../../test/data/appeals';
import ScheduleVeteran from './ScheduleVeteran';
import { queueWrapper as Wrapper } from '../../../test/data/stores/queueStore';

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
  }
};

const defaultArgs = {
  appealId: amaAppeal.externalId,
};

const Template = (args) => {
  const { storeArgs, componentArgs } = args;

  return (
    <Wrapper {...storeArgs}>
      <ScheduleVeteran
        {...defaultArgs}
        {...componentArgs}
      />
    </Wrapper>

  );
};

export const Default = Template.bind({});

export const OpenHearing = Template.bind({});
OpenHearing.args = {
  componentArgs: {
    appealId: openHearingAppeal.externalId
  }
};

export const FullHearingDay = Template.bind({});
FullHearingDay.args = {
  storeArgs: {
    components: {
      forms: {
        assignHearing: {
          ...defaultAssignHearing,
          hearingDay: hearingDateOptions.filter((date) => date.value.filledSlots >= date.value.totalSlots)[0].value
        }
      }
    }
  }
};

export const Virtual = Template.bind({});
Virtual.args = {
  storeArgs: {
    components: {
      forms: {
        assignHearing: {
          ...defaultAssignHearing,
          regionalOffice: {
            key: defaultHearing.regionalOfficeKey,
            timezone: defaultHearing.regionalOfficeTimezone
          },
          virtualHearing: virtualHearing.virtualHearing
        }
      }
    }
  }
};

export const Video = Template.bind({});
Video.args = {
  storeArgs: {
    components: {
      forms: {
        assignHearing: {
          ...defaultAssignHearing,
          regionalOffice: {
            key: defaultHearing.regionalOfficeKey,
            timezone: defaultHearing.regionalOfficeTimezone
          },
          hearingLocation: scheduleHearingDetails.hearingLocation
        }
      }
    }
  }
};
