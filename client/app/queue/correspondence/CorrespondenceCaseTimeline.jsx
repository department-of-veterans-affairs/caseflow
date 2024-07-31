import React from 'react';
import PropTypes from 'prop-types';
import CorrespondenceTaskRows from './CorrespondenceTaskRows';
const CorrespondenceCaseTimeline = (props) => {


  const formatTaskData = () => {
    return (props.correspondence.tasksUnrelatedToAppeal.map((task) => {
      return {
        assignedOn: task.assigned_at,
        assignedTo: task.assigned_to,
        label: task.type,
        instructions: task.instructions,
        availableActions: task.available_actions,
        uniqueId: task.uniqueId
      };
    }));
  };

  return (
    <React.Fragment>
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <CorrespondenceTaskRows
            organizations={props.organizations}
            correspondence={props.correspondence}
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
