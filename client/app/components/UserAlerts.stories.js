import React from 'react';

import ReduxBase from './ReduxBase';
import UserAlerts from './UserAlerts';
import reducers from './common/reducers';

export default {
  title: 'Commons/Components/UserAlerts',
  component: UserAlerts
};

const Template = (args) => (
  <ReduxBase
    initialState={{ components: { alerts: args.alerts } }}
    reducer={reducers}
  >
    <UserAlerts />
  </ReduxBase>
);

export const Basic = Template.bind({});
Basic.args = {
  alerts: [
    {
      type: 'success',
      title: 'Success Alert Title',
      message: 'Successful Alert!'
    },
    {
      type: 'info',
      title: 'Info Alert Title',
      message: 'Info Alert!'
    },
    {
      type: 'warning',
      title: 'Warn Alert Title',
      message: 'Warning Alert!'
    },
    {
      type: 'error',
      title: 'Error Alert Title',
      message: 'Error Alert!'
    }
  ]
};
