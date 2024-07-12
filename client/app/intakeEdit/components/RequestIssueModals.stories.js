import React from 'react';

import RequestIssueAdditionModal from './RequestIssueAdditionModal';
import RequestIssueModificationModal from './RequestIssueModificationModal';
import RequestIssueRemovalModal from './RequestIssueRemovalModal';
import RequestIssueWithdrawalModal from './RequestIssueWithdrawalModal';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import { intakeEditReducer } from '../reducers/index';
import { store as data } from 'test/data/intakeEdit/store';
import thunk from 'redux-thunk';

const ReduxDecorator = (Story, options) => {
  const props = {
    ...options.args.data
  };

  const store = createStore(
    intakeEditReducer,
    props,
    compose(applyMiddleware(thunk))
  );

  return <Provider store={store} >
    <Story />
  </Provider>;
};

export default {
  title: 'Intake/Edit Issues/RequestIssueAdditionModal',
  component: RequestIssueAdditionModal,
  decorators: [ReduxDecorator],
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 700,
    },
  },
  args: {
    data
  },
  argTypes: {
    onCancel: { action: 'cancel' },
    moveToPendingReviewSection: { action: 'submit' },
  },
};

const props = {
  currentIssue: {
    id: '3145',
    benefitType: 'vha',
    decisionIssueId: null,
    description: 'Caregiver | Revocation/Discharge - Veterans Health Administration Seeded issue',
    nonRatingIssueDescription: 'Veterans Health Administration Seeded issue',
    decisionDate: '2023-11-08',
    ineligibleReason: null,
    ineligibleDueToId: null,
    decisionReviewTitle: 'Higher-Level Review',
    contentionText: 'Caregiver | Revocation/Discharge - Veterans Health Administration Seeded issue',
    vacolsId: null,
    vacolsSequenceId: null,
    vacolsIssue: null,
    endProductCleared: null,
    endProductCode: null,
    withdrawalDate: null,
    editable: true,
    examRequested: null,
    isUnidentified: null,
    notes: null,
    category: 'Caregiver | Revocation/Discharge',
    index: null,
    isRating: false,
    ratingIssueReferenceId: null,
    ratingDecisionReferenceId: null,
    ratingIssueProfileDate: null,
    approxDecisionDate: '2023-11-08',
    titleOfActiveReview: null,
    rampClaimId: null,
    verifiedUnidentifiedIssue: null,
    isPreDocketNeeded: null,
    mstChecked: false,
    pactChecked: false,
    vbmsMstChecked: false,
    vbmsPactChecked: false
  },
  issueIndex: 0,
};

const AdditionT = (args) => <RequestIssueAdditionModal {...args} />;
const WithdrawalT = (args) => <RequestIssueWithdrawalModal {...args} />;
const ModificationT = (args) => <RequestIssueModificationModal {...args} />;
const RemovalT = (args) => <RequestIssueRemovalModal {...args} />;

export const Addition = AdditionT.bind({});

export const Withdrawal = WithdrawalT.bind({});
Withdrawal.args = props;

export const Modification = ModificationT.bind({});
Modification.args = props;

export const Removal = RemovalT.bind({});
Removal.args = props;

