import React from 'react';
import PropTypes from 'prop-types';

export const ExistingAppealTasksView = (props) => {
  return (
    <div>
      <strong>Tasks: Appeal #{props.appeal.docketNumber}</strong>
    </div>
  );
};

ExistingAppealTasksView.propTypes = {
  appeal: PropTypes.object.isRequired
};

export default ExistingAppealTasksView;
