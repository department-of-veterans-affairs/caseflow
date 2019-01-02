import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export const claimantColumn = () => {
  return {
    header: 'Claimant',
    valueFunction: (task) => {
      return <Link to={`/queue/${task.type}/${task.id}`}>{task.claimant}</Link>;
    },
    getSortValue: (task) => task.claimant
  };
};

export const veteranParticipantIdColumn = () => {
  return {
    header: 'Veteran Participant Id',
    valueFunction: (task) => task.veteranParticipantId,
    getSortValue: (task) => task.veteranParticipantId
  };
};

export const decisionReviewTypeColumn = () => {
  return {
    header: 'Type',
    valueFunction: (task) => task.type,
    getSortValue: (task) => task.type,
    // order determines where this column displays
    // make it -1 so this column is always last
    order: -1
  };
};
