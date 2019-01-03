import React from 'react';

export const claimantColumn = () => {
  return {
    header: 'Claimant',
    valueFunction: (task) => {
      return <a href={`/decision_reviews/${task.business_line}/tasks/${task.id}`}>{task.claimant.name}</a>;
    },
    getSortValue: (task) => task.claimant.name
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
