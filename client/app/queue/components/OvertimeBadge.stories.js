import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../../../app/queue/reducers';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import OvertimeBadge from './OvertimeBadge';
import { setCanViewOvertimeStatus } from 'app/queue/uiReducer/uiActions';

export default {
  title: 'Commons/Components/Badges/OT Badge',
  component: OvertimeBadge,
  parameters: {
    layout: 'centered',
  },
  args: {
    appeal: {
      overtime: true
    },
    canViewOvertimeStatus: true,
    featureToggles: {
      overtime_revamp: true
    }, 
  }
};

const getStore = () => createStore(rootReducer, applyMiddleware(thunk));
const store = getStore();
store.dispatch(setCanViewOvertimeStatus(true));

const Template = (args) => (
  <Provider store={store}>
    <OvertimeBadge {...args} />
  </Provider>
);

export const OTBadge = Template.bind({});
