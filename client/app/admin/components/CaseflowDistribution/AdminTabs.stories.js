import React from 'react';
import { css } from 'glamor';

import { MemoryRouter } from 'react-router';
// import { ActiveLiver } from './ActiveLiver';
import AdminTabs from './AdminTabs';

import { Tabs } from 'app/components/tabs/Tabs';
import { Tab } from 'app/components/tabs/Tab';

import InteractableLever from './InteractableLever';
import { levers } from 'test/data/adminCaseDistributionLevers';
import Alert from 'app/components/Alert';
import UserAlerts from 'app/components/UserAlerts';
// import { VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE,
//   VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE,
//   VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE } from '../client/COPY.json';

// const judgeTeam = createJudgeTeam(1)[0];

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

export default {
  title: 'Admin/Caseflow Distribution/AdminTabs',
  component: AdminTabs,
  decorators: [RouterDecorator],
  args: {
    showDistributionToggles: false,
  },
  argTypes: {
    onUpdate: { action: 'onUpdate' }
  }
};

// const Template = (args) => (
//   // <table className={tableStyling}>
//   //   <tbody>
//       <AdminTabs {...args} />
//   //   </tbody>
//   // </table>
// );

// export const Default = Template.bind({});

export const tabs = (args) => (

  <Tabs {...args}>
    <Tab title="Case Distribution" value="1">
      <strong>Caseflow Distribution content</strong>
      <p>This is the first lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen.</p>
      {/* <Alert
            type="info"
            message={VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE}
          /> */}
      {/* <React.Fragment>
        <UserAlerts />
        <Alert
          type="Info"
          message='You cannot add more veterans to this hearing day, but you can edit existing entries'
        />
      </React.Fragment> */}

      { levers.map((lever) => {
        return lever ? (
          <InteractableLever key={lever.item} lever={lever} />
        ) : null;
      })}

    </Tab>
    <Tab title="Veteran Extract" value="2">
      Veteran Extract content
    </Tab>
  </Tabs>
);
