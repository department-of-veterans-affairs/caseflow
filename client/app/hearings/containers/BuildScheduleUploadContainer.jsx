import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import ApiUtil from '../../util/ApiUtil';
import { SPREADSHEET_TYPES } from '../constants';
import {
  onFileTypeChange,
  onRoCoStartDateChange,
  onRoCoEndDateChange,
  onRoCoFileUpload,
  onJudgeStartDateChange,
  onJudgeEndDateChange,
  onJudgeFileUpload,
  toggleUploadContinueLoading,
  updateUploadFormErrors,
  updateRoCoUploadFormErrors,
  updateJudgeUploadFormErrors,
  unsetUploadErrors
} from '../actions/hearingScheduleActions';
import BuildScheduleUpload from '../components/BuildScheduleUpload';

export class BuildScheduleUploadContainer extends React.Component {

  componentWillUnmount = () => {
    this.props.unsetUploadErrors();
  };

  validateDatesAndFile = (onFailure, startDate, endDate, file) => {
    if (!(startDate && endDate && file)) {
      onFailure(['Please make sure all required fields are filled in.']);

      return false;
    }
    if (endDate < startDate) {
      onFailure(['The end date must be after the start date.']);

      return false;
    }

    return true;
  };

  validateData = () => {
    if (this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      return this.validateDatesAndFile(
        this.props.updateRoCoUploadFormErrors,
        this.props.roCoStartDate,
        this.props.roCoEndDate,
        this.props.roCoFileUpload
      );
    }
    if (this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      return this.validateDatesAndFile(
        this.props.updateJudgeUploadFormErrors,
        this.props.judgeStartDate,
        this.props.judgeEndDate,
        this.props.judgeFileUpload
      );
    }
    this.props.updateUploadFormErrors('Please select a file type.');

    return false;
  };

  formatData = () => {
    let schedulePeriod = {};

    if (this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      schedulePeriod = {
        file: this.props.roCoFileUpload.file,
        startDate: this.props.roCoStartDate,
        endDate: this.props.roCoEndDate,
        type: this.props.fileType
      };
    }

    if (this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      schedulePeriod = {
        file: this.props.judgeFileUpload.file,
        startDate: this.props.judgeStartDate,
        endDate: this.props.judgeEndDate,
        type: this.props.fileType
      };
    }

    return ApiUtil.convertToSnakeCase(schedulePeriod);
  };

  createSchedulePeriod = () => {
    this.props.toggleUploadContinueLoading();

    if (!this.validateData()) {
      this.props.toggleUploadContinueLoading();

      return;
    }

    const data = this.formatData();

    ApiUtil.post('/hearings/schedule_periods', { data: { schedule_period: data } }).
      then((response) => {
        this.props.toggleUploadContinueLoading();
        this.props.history.push(`/schedule/build/upload/${response.body.id}`);
      }).
      catch(({ response }) => {
        // Map unspecified errors
        const errors = Array.isArray(response.body?.errors) ?
          response.body.errors.map((error) => error.details) :
          ['ValidationError::UnspecifiedError'];

        // Display the errors based on the spreadsheet type
        if (this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
          this.props.updateRoCoUploadFormErrors(errors);
        } else if (this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
          this.props.updateJudgeUploadFormErrors(errors);
        }

        // Toggle the continue upload
        this.props.toggleUploadContinueLoading();
      });
  };

  render() {
    return <BuildScheduleUpload
      fileType={this.props.fileType}
      onFileTypeChange={this.props.onFileTypeChange}
      roCoStartDate={this.props.roCoStartDate}
      onRoCoStartDateChange={this.props.onRoCoStartDateChange}
      roCoEndDate={this.props.roCoEndDate}
      onRoCoEndDateChange={this.props.onRoCoEndDateChange}
      roCoFileUpload={this.props.roCoFileUpload}
      onRoCoFileUpload={this.props.onRoCoFileUpload}
      judgeStartDate={this.props.judgeStartDate}
      onJudgeStartDateChange={this.props.onJudgeStartDateChange}
      judgeEndDate={this.props.judgeEndDate}
      onJudgeEndDateChange={this.props.onJudgeEndDateChange}
      judgeFileUpload={this.props.judgeFileUpload}
      onJudgeFileUpload={this.props.onJudgeFileUpload}
      uploadFormErrors={this.props.uploadFormErrors}
      uploadRoCoFormErrors={this.props.uploadRoCoFormErrors}
      uploadJudgeFormErrors={this.props.uploadJudgeFormErrors}
      uploadContinueLoading={this.props.uploadContinueLoading}
      onUploadContinue={this.createSchedulePeriod}
    />;
  }
}

BuildScheduleUploadContainer.propTypes = {

  /**
   * Required Props
   */
  history: PropTypes.object,

  /**
   * Optional Props
   */
  fileType: PropTypes.string,
  uploadContinueLoading: PropTypes.bool,
  roCoStartDate: PropTypes.string,
  roCoEndDate: PropTypes.string,
  judgeStartDate: PropTypes.string,
  judgeEndDate: PropTypes.string,
  uploadFormErrors: PropTypes.string,
  judgeFileUpload: PropTypes.object,
  roCoFileUpload: PropTypes.object,
  uploadRoCoFormErrors: PropTypes.array,
  uploadJudgeFormErrors: PropTypes.array,

  /**
   * Functions
   */
  updateUploadFormErrors: PropTypes.func,
  onRoCoFileUpload: PropTypes.func,
  onJudgeFileUpload: PropTypes.func,
  updateJudgeUploadFormErrors: PropTypes.func,
  updateRoCoUploadFormErrors: PropTypes.func,
  toggleUploadContinueLoading: PropTypes.func,
  unsetUploadErrors: PropTypes.func,
  onFileTypeChange: PropTypes.func,
  onRoCoStartDateChange: PropTypes.func,
  onRoCoEndDateChange: PropTypes.func,
  onJudgeStartDateChange: PropTypes.func,
  onJudgeEndDateChange: PropTypes.func,

};

const mapStateToProps = (state) => ({
  fileType: state.hearingSchedule.fileType,
  roCoStartDate: state.hearingSchedule.roCoStartDate,
  roCoEndDate: state.hearingSchedule.roCoEndDate,
  roCoFileUpload: state.hearingSchedule.roCoFileUpload,
  judgeStartDate: state.hearingSchedule.judgeStartDate,
  judgeEndDate: state.hearingSchedule.judgeEndDate,
  judgeFileUpload: state.hearingSchedule.judgeFileUpload,
  uploadFormErrors: state.hearingSchedule.uploadFormErrors,
  uploadRoCoFormErrors: state.hearingSchedule.uploadRoCoFormErrors,
  uploadJudgeFormErrors: state.hearingSchedule.uploadJudgeFormErrors,
  uploadContinueLoading: state.hearingSchedule.uploadContinueLoading
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFileTypeChange,
  onRoCoStartDateChange,
  onRoCoEndDateChange,
  onRoCoFileUpload,
  onJudgeStartDateChange,
  onJudgeEndDateChange,
  onJudgeFileUpload,
  toggleUploadContinueLoading,
  updateUploadFormErrors,
  updateRoCoUploadFormErrors,
  updateJudgeUploadFormErrors,
  unsetUploadErrors
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(BuildScheduleUploadContainer));
