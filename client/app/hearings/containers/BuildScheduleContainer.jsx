import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import {
  onReceivePastUploads,
  unsetSuccessMessage,
  onConfirmAssignmentsUpload
} from '../actions/hearingScheduleActions';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../../constants/AppConstants';
import BuildSchedule from '../components/BuildSchedule';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const vacolsLoadingMessage = 'We are uploading to Caseflow. Please don\'t click the back or refresh buttons until ' +
  'the upload is finished.';
const pastScheduleLoadingMessage = 'Loading past schedule uploads...';

const vacolsLoadingErrorTitle = { title: 'We could not complete your Caseflow upload' };
const pastScheduleLoadingErrorTitle = { title: 'We could not load past schedule uploads' };

const vacolsLoadingErrorMsg = <div>
  We encountered an error uploading to Caseflow. Please use the 'Go Back' link to try again.
  if the problem persists you can check the status of our applications or submit a help
  request using the links in the footer.<br></br><br></br>
  <span><Link to="/schedule/build/upload"> Go Back</Link></span>
</div>;

const pastScheduleLoadingErrorMsg = <div>
  We encountered an error uploading past schedule uploads. Please use the 'Go Back' link to try again.
  if the problem persists you can check the status of our applications or submit a help
  request using the links in the footer.<br></br><br></br>
  <span><Link to="/schedule"> Go Back</Link></span>
</div>;

class BuildScheduleContainer extends React.PureComponent {

  componentWillUnmount() {
    this.props.unsetSuccessMessage();
  }

  loadPastUploads = () => {
    return ApiUtil.get('/hearings/schedule_periods.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(response.body);
      const schedulePeriods = _.keyBy(resp.schedulePeriods, 'id');

      this.props.onReceivePastUploads(schedulePeriods);
    });
  };

  shouldNotSendAssignments = () =>
    _.isEmpty(this.props.schedulePeriod) ||
      this.props.schedulePeriod.finalized === true ||
      !this.props.vacolsUpload;

  sendAssignments = () => {
    if (this.shouldNotSendAssignments()) {
      return Promise.resolve();
    }

    return ApiUtil.patch(`/hearings/schedule_periods/${this.props.schedulePeriod.id}`).then(() => {
      this.props.onConfirmAssignmentsUpload();
    });
  };

  createLoadPromise = () => Promise.all([
    this.loadPastUploads(),
    this.sendAssignments()
  ]);

  render = () => {
    const loadingMessage = this.shouldNotSendAssignments() ? pastScheduleLoadingMessage : vacolsLoadingMessage;
    const errorTitle = this.shouldNotSendAssignments() ? pastScheduleLoadingErrorTitle : vacolsLoadingErrorTitle;
    const errorMsg = this.shouldNotSendAssignments() ? pastScheduleLoadingErrorMsg : vacolsLoadingErrorMsg;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
        message: loadingMessage
      }}
      failStatusMessageProps={errorTitle}
      failStatusMessageChildren={errorMsg}>
      <BuildSchedule
        pastUploads={this.props.pastUploads}
        schedulePeriod={this.props.schedulePeriod}
        displaySuccessMessage={this.props.displaySuccessMessage}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

BuildScheduleContainer.propTypes = {
  displaySuccessMessage: PropTypes.bool,
  onConfirmAssignmentsUpload: PropTypes.func,
  onReceivePastUploads: PropTypes.func,
  pastUploads: PropTypes.object,
  schedulePeriod: PropTypes.object,
  unsetSuccessMessage: PropTypes.func,
  vacolsUpload: PropTypes.bool
};

const mapStateToProps = (state) => ({
  pastUploads: state.hearingSchedule.pastUploads,
  schedulePeriod: state.hearingSchedule.schedulePeriod,
  vacolsUpload: state.hearingSchedule.vacolsUpload,
  displaySuccessMessage: state.hearingSchedule.displaySuccessMessage
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceivePastUploads,
  unsetSuccessMessage,
  onConfirmAssignmentsUpload
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(BuildScheduleContainer);
