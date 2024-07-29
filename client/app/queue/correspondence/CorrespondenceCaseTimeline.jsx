import React from 'react';
import PropTypes from 'prop-types';
import CorrespondenceTaskRows from './CorrespondenceTaskRows';
const CorrespondenceCaseTimeline = (props) => {

  const buildActions = (isAssignedToOrg) => {
    const actions = [];

    const modifiedUserLabel = isAssignedToOrg === 'Organization' ? 'Assign to person' : 'Re-assign to person';

    actions.push({ value: 'changeTask', label: 'Change task type' });
    actions.push({ value: 'changeTask', label: 'Assign to team' });
    actions.push({ value: 'changeTask', label: modifiedUserLabel });
    actions.push({ value: 'changeTask', label: 'Mark task complete' });
    actions.push({ value: 'changeTask', label: 'Return to Inbound Ops' });
    actions.push({ value: 'changeTask', label: 'Cancel task' });

    return actions;
  };

  const getAvailableActions = (task, type) => {
    if (props.organizations.includes(task.assigned_to) || props.userCssId === task.assigned_to) {
      return buildActions(type);
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
        availableActions: getAvailableActions(task, task.assigned_to_type),
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
