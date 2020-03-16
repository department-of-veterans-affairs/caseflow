import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import CheckboxGroup from '../../components/CheckboxGroup';
import { JUDGE_ADDRESS_MTV_ISSUE_SELECTION_LABEL } from '../../../COPY';

const getDisplayOptions = (issues) => {
  // CheckboxGroup expects options with id (string) & label
  return issues.map(({ id, description }, idx) => ({ id: id.toString(),
    label: `${idx + 1}. ${description}` }));
};

export const MTVIssueSelection = ({ issues, onChange }) => {
  const [selectedIssues, setSelectedIssues] = useState({});

  useEffect(() => {
    const issueIds = Object.entries(selectedIssues).map(([value]) => {
      return value;
    });

    if (onChange) {
      onChange({ issueIds });
    }
  }, [selectedIssues]);

  return (
    <CheckboxGroup
      vertical
      name="issues"
      label={JUDGE_ADDRESS_MTV_ISSUE_SELECTION_LABEL}
      onChange={(event) => {
        setSelectedIssues((prevVals) => ({
          ...prevVals,
          [event.target.getAttribute('id')]: event.target.checked
        }));
      }}
      value={selectedIssues}
      options={getDisplayOptions(issues)}
      strongLabel
    />
  );
};

MTVIssueSelection.propTypes = {
  issues: PropTypes.array,
  onChange: PropTypes.func
};
