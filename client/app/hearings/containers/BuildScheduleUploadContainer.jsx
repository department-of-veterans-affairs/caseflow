import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';
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
      onFailure('ValidationError::MissingStartDateEndDateFile');

      return false;
    }
    if (endDate < startDate) {
      onFailure('ValidationError::EndDateTooEarly');

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
        if (_.has(response.body, 'error')) {
          if (this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
            this.props.updateRoCoUploadFormErrors(response.body.error);
          }
          if (this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
            this.props.updateJudgeUploadFormErrors(response.body.error);
          }
          this.props.toggleUploadContinueLoading();

          return;
        }
        this.props.toggleUploadContinueLoading();
        this.props.history.push(`/schedule/build/upload/${response.body.id}`);
      }, () => {
        if (this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
          this.props.updateRoCoUploadFormErrors('ValidationError::UnspecifiedError');
        }
        if (this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
          this.props.updateJudgeUploadFormErrors('ValidationError::UnspecifiedError');
        }
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
