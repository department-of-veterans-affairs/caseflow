import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { createStore } from 'redux';

import ReduxBase from '../components/ReduxBase';
import reducer from './reducers';

import AddCavcRemandView from './AddCavcRemandView';

export default {
  title: 'Queue/AddCavcRemandView',
  component: AddCavcRemandView,
};

const appealId = '1234';
const decisionIssues = [{ description: 'This is the description of the decision issue.' }];
const highlightFormItems = false;
const backEndError = null;
const initialState = {
  queue: {
    appealDetails: {
      [appealId]: {
        decisionIssues
      },
    },
    stagedChanges: {
      appeals: {}
    }
  },
  ui: {
    highlightFormItems,
    messages: {
      error: backEndError
    },
    modals: {
      cancelCheckout: false
    },
    featureToggles: {
      special_issues_revamp: false
    },
    saveState: {
      savePending: false,
      saveSuccessful: false
    }
  }
};

const Template = (args) => (
  <BrowserRouter>
    <ReduxBase initialState={initialState} store={createStore(reducer, initialState)} reducer={reducer}>
      <AddCavcRemandView appealId={appealId} {...args} />
    </ReduxBase>
  </BrowserRouter>
);

export const Default = Template.bind({});
