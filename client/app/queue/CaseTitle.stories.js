import React from 'react';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import CaseTitleComponent from './CaseTitle';

export default {
  title: 'Queue/Case Details/Case Title',
  component: CaseTitleComponent,
  parameters: {
    layout: 'centered',
  },
  args: {
    appeal: {
      canViewOvertimeStatus: false,
      contestedClaim: true,
      overtime: true,
      hearings: [
        {
          heldBy: 'ExampleJudgeName',
          disposition: 'held',
          date: '2020-01-15',
          type: 'AMA'
        }
      ]
    },
    isHorizontal: false,
    task: {
      appeal: {
        canViewOvertimeStatus: false,
        contestedClaim: true,
        overtime: true
      },
    }
  }
};

const getStore = () => createStore(rootReducer, applyMiddleware(thunk));
const store = getStore();

const Template = (args) => (
  <Provider store={store}>
    <CaseTitleComponent {...args} />
  </Provider>
);

export const CaseTitle = Template.bind({});
