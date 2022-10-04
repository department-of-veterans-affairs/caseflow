import React from 'react';

import { CaseTitleDetails } from './CaseTitleDetails';

import { amaAppeal } from '../../test/data/appeals';

export default {
  title: 'Queue/CaseTitleDetails',
  component: CaseTitleDetails,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  },
};

const Template = (args) => (
  <CaseTitleDetails {...args} />
);

export const AppealInHearingDocket = Template.bind({});
AppealInHearingDocket.args = {
  appeal: {
    ...amaAppeal,
    readableHearingRequestType: 'Central'
  },
  appealId: amaAppeal.id,
  requestPatch: () => {},
  userIsVsoEmployee: false,
  featureToggles: {},
  legacyJudgeTasks: []
};

export const AppealNotInHearingDocket = Template.bind({});
AppealNotInHearingDocket.args = {
  ...AppealInHearingDocket.args,
  appeal: {
    ...amaAppeal,
    docketName: 'Evidence',
    readableHearingRequestType: 'Central'
  }
};
