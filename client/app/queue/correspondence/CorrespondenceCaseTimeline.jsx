import React from 'react';
import PropTypes from 'prop-types';
import CorrespondenceTaskRows from './CorrespondenceTaskRows';
const CorrespondenceCaseTimeline = (props) => {

  const actions = [
    { value: 'changeTask', label: 'Change task type' },
    { value: 'changeTask', label: 'Assign to team' },
    { value: 'changeTask', label: 'Assign to person' },
    { value: 'changeTask', label: 'Mark task complete' },
    { value: 'changeTask', label: 'Return to Inbound Ops' },
    { value: 'changeTask', label: 'Cancel task' },
  ];

  const getAvailableActions = (task) => {
    if (props.organizations.includes(task.assigned_to)) {
      return actions;
    }

    if (props.userCssId === task.assigned_to) {
      return actions;
    }

    return [];

  };

  const formatTaskData = () => {
    return (props.correspondence.tasksUnrelatedToAppeal.map((task) => {
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
  userCssId: PropTypes.string
};

export default CorrespondenceCaseTimeline;
