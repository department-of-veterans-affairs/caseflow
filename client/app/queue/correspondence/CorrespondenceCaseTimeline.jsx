import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import CorrespondenceTaskRows from './CorrespondenceTaskRows';
import Alert from '../../components/Alert';
import {
  setTaskNotRelatedToAppealBanner,
  setShowActionsDropdown } from './correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceCaseTimeline = (props) => {

  const { taskNotRelatedToAppealBanner, correspondenceInfo } = props;

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
  correspondence: PropTypes.object,
  correspondenceInfo: PropTypes.object,
  taskNotRelatedToAppealBanner: PropTypes.object,
  organizations: PropTypes.array,
  userCssId: PropTypes.string
};

const mapStateToProps = (state) => ({
  correspondences: state.intakeCorrespondence.correspondences,
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  tasksUnrelatedToAppeal: state.correspondenceDetails.tasksUnrelatedToAppeal,
  showActionsDropdown: state.correspondenceDetails.showActionsDropdown,
  dubuggo: state.correspondenceDetails.dubuggo,
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setTaskNotRelatedToAppealBanner,
    setShowActionsDropdown
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceCaseTimeline);
