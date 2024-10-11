import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import CorrespondenceTaskRows from './CorrespondenceTaskRows';
import Alert from '../../components/Alert';
import {
  setTaskNotRelatedToAppealBanner,
  setTasksUnrelatedToAppealEmpty,
  setUnrelatedTaskList
} from './correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceCaseTimeline = (props) => {

  const { taskNotRelatedToAppealBanner, correspondenceInfo, unrelatedTaskList } = props;

  useEffect(() => {
    // If unrelatedTaskList is empty, initialize it with tasksUnrelatedToAppeal
    if (unrelatedTaskList.length === 0 && correspondenceInfo.tasksUnrelatedToAppeal.length > 0) {
      props.setUnrelatedTaskList(correspondenceInfo.tasksUnrelatedToAppeal);
    }

    // Mark tasks as empty if there are no unrelated tasks
    if (correspondenceInfo.tasksUnrelatedToAppeal.length === 0) {
      props.setTasksUnrelatedToAppealEmpty(true);
    }

  }, [correspondenceInfo.tasksUnrelatedToAppeal, unrelatedTaskList.length]);

  useEffect(() => {

    if (correspondenceInfo.tasksUnrelatedToAppeal.length === 0) {
      props.setTasksUnrelatedToAppealEmpty(true);
    }

  }, []);

  return (
    <React.Fragment>
      {(Object.keys(taskNotRelatedToAppealBanner).length > 0) && (
        <div className="correspondence-details-alert-banner">
          <Alert
            type={taskNotRelatedToAppealBanner.type}>
            {taskNotRelatedToAppealBanner.message}
          </Alert>
        </div>
      )}
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <CorrespondenceTaskRows
            organizations={props.organizations}
            correspondence={props.correspondence}
            taskList={unrelatedTaskList}
            statusSplit
          />
        </tbody>
      </table>
    </React.Fragment>
  );
};

CorrespondenceCaseTimeline.propTypes = {
  loadCorrespondence: PropTypes.func,
  setUnrelatedTaskList: PropTypes.func,
  setTasksUnrelatedToAppealEmpty: PropTypes.func,
  correspondence: PropTypes.object,
  correspondenceInfo: PropTypes.object,
  taskNotRelatedToAppealBanner: PropTypes.object,
  unrelatedTaskList: PropTypes.array,
  organizations: PropTypes.array,
  tasksToDisplay: PropTypes.array,
  userCssId: PropTypes.string
};

const mapStateToProps = (state) => ({
  correspondences: state.intakeCorrespondence.correspondences,
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  tasksUnrelatedToAppeal: state.correspondenceDetails.tasksUnrelatedToAppeal,
  tasksUnrelatedToAppealEmpty: state.correspondenceDetails.tasksUnrelatedToAppealEmpty,
  unrelatedTaskList: state.correspondenceDetails.unrelatedTaskList,
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setTaskNotRelatedToAppealBanner,
    setTasksUnrelatedToAppealEmpty,
    setUnrelatedTaskList
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceCaseTimeline);
