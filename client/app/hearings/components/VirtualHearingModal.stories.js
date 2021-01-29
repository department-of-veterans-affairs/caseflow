import React from 'react';

import { amaHearing } from '../../../test/data/hearings';
import VirtualHearingModal from "./VirtualHearingModal";

export default {
  title: 'Hearings/Components/VirtualHearingModal',
  component: VirtualHearingModal,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 960,
    },
  },
  argTypes: {
    update: { action: 'change' },
    reset: { action: 'change' },
    submit: { action: 'submit' },
    closeModal: { action: 'cancel' }
  }
};

const defaultArgs = {
  hearing: amaHearing,
  virtualHearing: amaHearing.virtualHearing,
  open: true,
  scrollLock: false
};

const Template = (args) => <VirtualHearingModal {...args} {...defaultArgs} />;

export const ChangeToVirtual = Template.bind({});
ChangeToVirtual.args = { type: 'change_to_virtual' };
ChangeToVirtual.parameters = {
  docs: {
    storyDescription:
      'Virtual hearing modal when changing a video hearing to virtual',
  },
};

export const ChangeFromVirtual = Template.bind({});
ChangeFromVirtual.args = { type: 'change_from_virtual' }
ChangeFromVirtual.parameters = {
  docs: {
    storyDescription:
      'Change a virtual hearing back to video',
  },
};

export const ChangeHearingTime = Template.bind({});
ChangeHearingTime.args = { type: 'change_hearing_time', timeWasEdited: true };
ChangeHearingTime.parameters = {
  docs: {
    storyDescription:
      'Change the hearing time of a virtual hearing',
  },
};

export const ChangeEmailOrTimezone = Template.bind({});
ChangeEmailOrTimezone.args = {
  type: 'change_email_or_timezone',
  representativeEmailEdited: true,
  representativeTzEdited: true,
  appellantEmailEdited: true,
  appellantTzEdited: true
};
ChangeEmailOrTimezone.parameters = {
  docs: {
    storyDescription:
      'Change the email or timezone of a virtual hearing',
  },
};
