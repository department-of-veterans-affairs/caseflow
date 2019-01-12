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

const createFilterDropdown = (values) => {
  return values.map((value) => {
    return {
      value,
      displayText: value
    };
  });
};

export const decisionReviewTypeColumn = (onFilter, isFilterOpen, onFilterToggle, checkSelectedValue) => {
  return {
    header: 'Type',
    align: 'left',
    valueFunction: (task) => task.type,
    label: 'Filter by type',
    valueName: 'type',
    getFilterValues: createFilterDropdown(['Clear category filter', 'Board Grant',
      'Higher-Level Review', 'Remand - Supplemental Claim',
      'Supplemental Claim']),
    anyFiltersAreSet: false,
    isDropdownFilterOpen: isFilterOpen,
    toggleDropdownFilterVisiblity: onFilterToggle,
    setSelectedValue: onFilter,
    useCheckbox: true,
    checkSelectedValue: checkSelectedValue,
    // order determines where this column displays
    // make it -1 so this column is always last
    order: -1
  };
};
