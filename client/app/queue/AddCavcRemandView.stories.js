import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { createStore } from 'redux';

import ReduxBase from '../components/ReduxBase';
import reducer from './reducers';

import AddCavcRemandView from './AddCavcRemandView';

export default {
  title: 'Queue/AddCavcRemandView',
  component: AddCavcRemandView,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    highlightInvalid: { control: { type: 'boolean' } },
    error: { control: { type: 'text' } },
  },
};

const appealId = '1234';
const decisionIssues = [{ description: 'This is the description of the decision issue.' }];
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
    highlightFormItems: false,
    messages: {
      error: null
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

const Template = (args) => {
  initialState.ui.highlightFormItems = args.highlightInvalid;
  initialState.ui.messages.error = args.error;

  return <BrowserRouter>
    <ReduxBase initialState={initialState} store={createStore(reducer, initialState)} reducer={reducer}>
      <AddCavcRemandView appealId={appealId} {...args} />
    </ReduxBase>
  </BrowserRouter>;
};

export const Default = Template.bind({});

export const ServerError = Template.bind({});
ServerError.args = { error: { title: 'Error', detail: 'We could not complete your request' } };
