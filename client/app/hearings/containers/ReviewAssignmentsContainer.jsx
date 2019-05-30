import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { LOGO_COLORS } from '../../constants/AppConstants';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ReviewAssignments from '../components/ReviewAssignments';
import {
  onReceiveSchedulePeriod,
  onClickConfirmAssignments,
  onClickCloseModal,
  onSchedulePeriodError,
  removeSchedulePeriodError,
  setVacolsUpload
} from '../actions/hearingScheduleActions';

export class ReviewAssignmentsContainer extends React.Component {

  componentWillUnmount = () => {
    this.props.removeSchedulePeriodError();
  };

  onConfirmAssignmentsUpload = () => {
    this.props.onClickCloseModal();
    this.props.setVacolsUpload();
    this.props.history.push('/schedule/build');
  };

  loadSchedulePeriod = () => {
    return ApiUtil.get(`/hearings/schedule_periods/${this.props.match.params.schedulePeriodId}`).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));
      const schedulePeriod = resp.schedulePeriod;

      this.props.onReceiveSchedulePeriod(schedulePeriod);
    }, (error) => {
      this.props.onSchedulePeriodError(error.response.body);
    });
  };

  createLoadPromise = () => Promise.all([
    this.loadSchedulePeriod()
  ]);

  render() {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
        message: 'We are assigning hearings...'
      }}
      failStatusMessageProps={{
        title: 'Unable to assign hearings. Please try again.'
      }}>
      <ReviewAssignments
        schedulePeriod={this.props.schedulePeriod}
        schedulePeriodError={this.props.schedulePeriodError}
        onClickConfirmAssignments={this.props.onClickConfirmAssignments}
        onClickCloseModal={this.props.onClickCloseModal}
        displayConfirmationModal={this.props.displayConfirmationModal}
        onConfirmAssignmentsUpload={this.onConfirmAssignmentsUpload}
        spErrorDetails={this.props.spErrorDetails}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  schedulePeriod: state.hearingSchedule.schedulePeriod,
  schedulePeriodError: state.hearingSchedule.schedulePeriodError,
  spErrorDetails: state.hearingSchedule.spErrorDetails,
  displayConfirmationModal: state.hearingSchedule.displayConfirmationModal
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveSchedulePeriod,
  onClickConfirmAssignments,
  onClickCloseModal,
  onSchedulePeriodError,
  removeSchedulePeriodError,
  setVacolsUpload
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ReviewAssignmentsContainer));
