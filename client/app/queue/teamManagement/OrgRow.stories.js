import React from 'react';
import { css } from 'glamor';

import { createJudgeTeam } from 'test/data/teamManagement';
import { MemoryRouter } from 'react-router';
import { OrgRow } from './OrgRow';

const judgeTeam = createJudgeTeam(1)[0];

const tableStyling = css({
  width: '100%',
  '& td': { border: 'none' },
  '& input': { margin: 0 }
});

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'Admin/Team Management/OrgRow',
  component: OrgRow,
  decorators: [RouterDecorator],
  args: {
    ...judgeTeam,
    showDistributionToggles: false
  },
  argTypes: {
    onUpdate: { action: 'onUpdate' },
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

export const JudgeTeam = Template.bind({});
JudgeTeam.args = {
  showDistributionToggles: true
};

export const JudgeTeamUnprivileged = Template.bind({});
JudgeTeamUnprivileged.args = {
  showDistributionToggles: true,
  current_user_can_toggle_priority_pushed_cases: false
};
JudgeTeamUnprivileged.storyName = 'Judge Team (w/o Editing Privs)';

export const Vso = Template.bind({});
Vso.args = {
  isRepresentative: true
};

export const Saved = Template.bind({});
Saved.args = {
  status: {
    error: false,
    loading: false,
    saved: true
  }
};

export const Saving = Template.bind({});
Saving.args = {
  status: {
    error: false,
    loading: true,
    saved: false
  }
};

export const Error = Template.bind({});
Error.args = {
  status: {
    error: true,
    loading: false,
    saved: false
  }
};
