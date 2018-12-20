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

export const veteranSsnColumn = () => {
  return {
    header: 'Veteran SSN',
    valueFunction: (task) => task.veteranSSN,
    getSortValue: (task) => task.veteranSSN
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
