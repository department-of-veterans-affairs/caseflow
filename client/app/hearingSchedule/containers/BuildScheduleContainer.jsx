import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { onReceivePastUploads, unsetSuccessMessage, onConfirmAssignmentsUpload } from '../actions';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../../constants/AppConstants';
import BuildSchedule from '../components/BuildSchedule';

class BuildScheduleContainer extends React.PureComponent {

  componentWillUnmount() {
    this.props.unsetSuccessMessage();
  }

  loadPastUploads = () => {
    return ApiUtil.get('/hearings/schedule_periods.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));
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

    const vacolsLoadingMessage = 'We are uploading your assignments to VACOLS';
    const pastScheduleLoadingMessage = 'Loading past schedule uploads...';
    const loadingMessage = this.shouldNotSendAssignments() ? pastScheduleLoadingMessage : vacolsLoadingMessage;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: loadingMessage
      }}
      failStatusMessageProps={{
        title: 'Unable to load past schedule uploads.'
      }}>
      <BuildSchedule
        pastUploads={this.props.pastUploads}
        schedulePeriod={this.props.schedulePeriod}
        displaySuccessMessage={this.props.displaySuccessMessage}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  pastUploads: state.pastUploads,
  schedulePeriod: state.schedulePeriod,
  vacolsUpload: state.vacolsUpload,
  displaySuccessMessage: state.displaySuccessMessage
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceivePastUploads,
  unsetSuccessMessage,
  onConfirmAssignmentsUpload
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(BuildScheduleContainer);
