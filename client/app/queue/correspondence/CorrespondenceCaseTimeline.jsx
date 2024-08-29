import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import CorrespondenceTaskRows from './CorrespondenceTaskRows';
import Alert from '../../components/Alert';
import {
  setTaskNotRelatedToAppealBanner,
  setTasksUnrelatedToAppealEmpty } from './correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceCaseTimeline = (props) => {

  const { taskNotRelatedToAppealBanner, correspondenceInfo } = props;

  useEffect(() => {

    if (correspondenceInfo.tasksUnrelatedToAppeal.length === 0) {
      props.setTasksUnrelatedToAppealEmpty(true);
    }

  }, []);

  return (
    <React.Fragment>
      { (Object.keys(taskNotRelatedToAppealBanner).length > 0) && (
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
            taskList={correspondenceInfo.tasksUnrelatedToAppeal}
            statusSplit
          />
        </tbody>
      </table>
    </React.Fragment>
  );
};

CorrespondenceCaseTimeline.propTypes = {
  loadCorrespondence: PropTypes.func,
  setTasksUnrelatedToAppealEmpty: PropTypes.func,
  correspondence: PropTypes.object,
  correspondenceInfo: PropTypes.object,
  taskNotRelatedToAppealBanner: PropTypes.object,
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
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setTaskNotRelatedToAppealBanner,
    setTasksUnrelatedToAppealEmpty
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceCaseTimeline);
