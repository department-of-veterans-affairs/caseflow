import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter as Router } from 'react-router-dom';

import SaveSearchModal from 'app/nonComp/components/ReportPage/SaveSearchModal';
import CombinedNonCompReducer from 'app/nonComp/reducers';
import { applyMiddleware, createStore, compose } from 'redux';

import thunk from 'redux-thunk';

const userSearchParamWithCondition = {
  savedSearch: {
    saveUserSearch: {
      radioStatus: 'all_statuses',
      radioStatusReportType: 'last_action_taken',
      reportType: 'status',
      timing: {
        range: null
      },
      conditions: [
        {
          options: {
            comparisonOperator: 'lessThan',
            valueOne: 5
          },
          condition: 'daysWaiting'
        },
        {
          condition: 'issueType',
          options: {
            issueTypes: [
              {
                value: 'Camp Lejune Family Member',
                label: 'Camp Lejune Family Member'
              },
              {
                value: 'Caregiver | Eligibility',
                label: 'Caregiver | Eligibility'
              }
            ]
          }
        },
        {
          condition: 'issueDisposition',
          options: {
            issueDispositions: [
              {
                label: 'Blank',
                value: 'blank'
              },
              {
                label: 'Denied',
                value: 'denied'
              },
              {
                label: 'Dismissed',
                value: 'dismissed'
              }
            ]
          }
        },
        {
          condition: 'decisionReviewType',
          options: {
            decisionReviewTypes: [
              {
                label: 'Higher-Level Reviews',
                value: 'HigherLevelReview'
              },
              {
                label: 'Supplemental Claims',
                value: 'SupplementalClaim'
              }
            ]
          }
        },
        {
          condition: 'personnel',
          options: {
            personnel: [
              {
                label: 'Karmen Deckow DDS',
                value: 'PTBRADFAVBAS'
              },
              {
                label: 'Gerard Parisian LLD',
                value: 'THOMAW2VACO'
              }
            ]
          }
        }
      ]
    }
  }
};

const ReduxDecorator = (Story, options) => {
  const props = {
    ...options.args.data
  };

  const store = createStore(
    CombinedNonCompReducer,
    props,
    compose(applyMiddleware(thunk))
  );

  return <Provider store={store} >
    <Router>
      <Story />
    </Router>
  </Provider>;
};

export default {
  title: 'Queue/NonComp/SavedSearches/Save Search Modal',
  component: SaveSearchModal,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <SaveSearchModal
      {...args}
    />
  );
};

export const SaveSearchModalTemplate = Template.bind({});

SaveSearchModalTemplate.story = {
  name: 'Save Search Modal'
};

SaveSearchModalTemplate.args = {
  data: { nonComp: { businessLineUrl: 'vha' }, savedSearch: userSearchParamWithCondition.savedSearch }
};

