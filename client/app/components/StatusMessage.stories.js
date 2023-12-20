import React from 'react';

import StatusMessage from './StatusMessage';

const statusTitle = 'Claim Held';
const statusMessages = [
  "We've recorded your explanation and placed the claim on hold. " +
  'You can try establishing another claim or go view held claims in your Work History.'
];

const successTitle = 'Success!';
const successChecklist = [
  'Reviewed Remand Decision',
  'Established EP: 170RMDAMC - AMC - Remand for Station 397 - ARC',
  'VACOLS Updated: Changed Location to 98'
];
const successMessage = <span>Joe Snuffy's (ID #222222222) claim has been processed.<br />
  You can now establish the next claim or return to your Work History.</span>;
const wayToGo = <span>Way to go!</span>;
const successMessages = [successMessage, wayToGo];

const alertTitle = 'Establishment Cancelled';
const alertMessages = [
  'We’ve recorded your explanation and placed the claim back in the queue.' +
  'You can try establishing another claim or go back to your Work History.'
];

const warningTitle = 'Unable to load document';
const warningChildren = (
  <span>
    Caseflow is experiencing technical difficulties and cannot load the document.<br />
    You can try <a>downloading the document</a> or try again later.
  </span>
);

const Template = (args) => <StatusMessage {...args} />;

export const Status = Template.bind({});
Status.args = { type: 'status', title: statusTitle, leadMessageList: statusMessages };

export const Success = Template.bind({});
Success.args = { type: 'success', title: successTitle, checklist: successChecklist, leadMessageList: successMessages };

export const Alert = Template.bind({});
Alert.args = { type: 'alert', title: alertTitle, leadMessageList: alertMessages };

export const Warning = Template.bind({});
Warning.args = { type: 'warning', title: warningTitle, children: warningChildren };
