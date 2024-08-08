import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import CorrespondenceTaskRows from './CorrespondenceTaskRows';
import Alert from '../../components/Alert';
import { setTaskNotRelatedToAppealBanner } from './correspondenceDetailsReducer/correspondenceDetailsActions';
const CorrespondenceCaseTimeline = (props) => {

  const {taskNotRelatedToAppealBanner} = props

  const getAvailableActions = (task) => {
    if (props.organizations.includes(task.assigned_to) || props.userCssId === task.assigned_to) {
      return task.available_actions;
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
        uniqueId: task.uniqueId
      };
    }));
  };

  return (
    <React.Fragment>
      { (Object.keys(taskNotRelatedToAppealBanner).length > 0) && (<Alert
 type={taskNotRelatedToAppealBanner.type}>
{taskNotRelatedToAppealBanner.message}
      </Alert>)}
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

const mapStateToProps = (state) => ({
  correspondences: state.intakeCorrespondence.correspondences,
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setTaskNotRelatedToAppealBanner
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceCaseTimeline);
