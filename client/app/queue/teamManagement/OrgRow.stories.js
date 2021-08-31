import React from 'react';
import { css } from 'glamor';

import { createJudgeTeam } from 'test/data/factory';
import { OrgRow } from './OrgRow';

const judgeTeam = createJudgeTeam(1)[0];

const tableStyling = css({
  width: '100%',
  '& td': { border: 'none' },
  '& input': { margin: 0 }
});

export default {
  title: 'Admin/Team Management/OrgRow',
  component: OrgRow,
  args: {
    ...judgeTeam,
    showPriorityPushToggles: true
  }
};

const Template = (args) => (
  <table className={tableStyling}>
    <tbody>
      <OrgRow {...args} />
    </tbody>
  </table>
);

export const Default = Template.bind({});

