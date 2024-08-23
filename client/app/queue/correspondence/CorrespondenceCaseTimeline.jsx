import React from 'react';
import PropTypes from 'prop-types';
import CorrespondenceTaskRows from './CorrespondenceTaskRows';
const CorrespondenceCaseTimeline = (props) => {

  const getAvailableActions = (task) => {
    const organizations = props.organizations || [];

    if (organizations.includes(task.assigned_to) || props.userCssId === task.assigned_to) {
      return task.available_actions || [];
    }

    return [];

  };

  const formatTaskData = () => {
    return (props.tasksToDisplay?.map((task) => {
      return {
        assignedOn: task.assigned_at,
        assignedTo: task.assigned_to,
        label: task.type,
        instructions: task.instructions,
        availableActions: getAvailableActions(task),
      };
    }));
  };

  return (
    <React.Fragment>
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <CorrespondenceTaskRows
            organizations={props.organizations}
            appeal={props.correspondence}
            taskList={formatTaskData()}
            statusSplit
          />
        </tbody>
      </table>
    </React.Fragment>
  );
};

CorrespondenceCaseTimeline.propTypes = {
  loadCorrespondence: PropTypes.func,
  correspondence: PropTypes.object,
  organizations: PropTypes.array,
  tasksToDisplay: PropTypes.array,
  userCssId: PropTypes.string
};

export default CorrespondenceCaseTimeline;
