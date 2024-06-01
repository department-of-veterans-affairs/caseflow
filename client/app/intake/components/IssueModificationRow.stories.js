import React from 'react';
import PropTypes from 'prop-types';
import issueModificationRow from 'app/intake/components/IssueModificationRow';
import Table from 'app/components/Table';

const issueModification = {
  id: 40,
  benefitType: 'vha',
  status: 'assigned',
  requestType: 'modification',
  removeOriginalIssue: false,
  nonratingIssueDescription: 'asdadadad',
  nonratingIssueCategory: 'Caregiver | Eligibility',
  decisionDate: '2024-05-06T08:06:48.224-04:00',
  decisionReason: null,
  requestReason: 'Consequatur eos sunt veritatis.',
  requestIssueId: 6887,
  withdrawalDate: null,
  requestIssue: {
    id: '6887',
    benefitType: 'vha',
    decisionDate: '2024-04-13',
    nonratingIssueCategory: 'Camp Lejune Family Member',
    nonratingIssueDescription: 'Seeded issue'
  },
  requestor: {
    id: '6385',
    fullName: 'Lauren Roth',
    cssId: 'CSSID6411050',
    stationID: '101'
  }
};

const issueAddition = {
  ...issueModification,
  requestType: 'addition',
};

const issueRemoval = {
  ...issueModification,
  requestType: 'removal',
};

const issueWithdrawal = {
  ...issueModification,
  requestType: 'withdrawal',
};

export default {
  title: 'Intake/Edit Issues/Issue Modification Row',
  decorators: [],
  parameters: {},
};

const BaseComponent = ({ content, field }) => (
  <div className="cf-intake-edit">
    <Table columns={[{ valueName: 'field' }, { valueName: 'content' }]} rowObjects={[{ field, content }]} />
  </div>
);

const PendingAdminReviewTemplate = (args) => {
  const Component = issueModificationRow({
    issueModificationRequests: { ...args },
    fieldTitle: 'Pending admin review',
    userIsVhaAdmin: true,
    onClickIssueAction: {}
  });

  return (
    <BaseComponent content={Component.content} field={Component.field} />
  );
};

export const pendingModificationReviewForAdmin = PendingAdminReviewTemplate.bind({});
pendingModificationReviewForAdmin.args = [issueModification];

export const pendingAdditionReviewForAdmin = PendingAdminReviewTemplate.bind({});
pendingAdditionReviewForAdmin.args = [issueAddition];

export const pendingWithdrawalForAdmin = PendingAdminReviewTemplate.bind({});
pendingWithdrawalForAdmin.args = [issueWithdrawal];

export const pendingRemovalForAdmin = PendingAdminReviewTemplate.bind({});
pendingRemovalForAdmin.args = [issueRemoval];

BaseComponent.propTypes = {
  content: PropTypes.element,
  field: PropTypes.string,
  userIsVhaAdmin: PropTypes.bool,
  onClickIssueAction: PropTypes.func
};
