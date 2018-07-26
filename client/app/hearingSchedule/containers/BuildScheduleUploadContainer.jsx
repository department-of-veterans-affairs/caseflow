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
} from '../actions';
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

  async createSchedulePeriod() {
    if (!this.validateData()) {
      return;
    }

    const data = this.formatData();

    ApiUtil.post('/hearings/schedule_periods', { data }).
      then((response) => {
        if (_.has(response.body, 'error')) {
          if (this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
            this.props.updateRoCoUploadFormErrors(response.body.error);
          }
          if (this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
            this.props.updateJudgeUploadFormErrors(response.body.error);
          }

          return;
        }
        this.props.history.push(`/schedule/build/upload/${response.body.id}`);
      }, () => {
        if (this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
          this.props.updateRoCoUploadFormErrors('ValidationError::UnspecifiedError');
        }
        if (this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
          this.props.updateJudgeUploadFormErrors('ValidationError::UnspecifiedError');
        }
      });
  }

  onUploadContinue = () => {
    this.props.toggleUploadContinueLoading();
    Promise.resolve(this.createSchedulePeriod()).
      then(this.props.toggleUploadContinueLoading());
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
      onUploadContinue={this.onUploadContinue}
    />;
  }
}

const mapStateToProps = (state) => ({
  fileType: state.fileType,
  roCoStartDate: state.roCoStartDate,
  roCoEndDate: state.roCoEndDate,
  roCoFileUpload: state.roCoFileUpload,
  judgeStartDate: state.judgeStartDate,
  judgeEndDate: state.judgeEndDate,
  judgeFileUpload: state.judgeFileUpload,
  uploadFormErrors: state.uploadFormErrors,
  uploadRoCoFormErrors: state.uploadRoCoFormErrors,
  uploadJudgeFormErrors: state.uploadJudgeFormErrors,
  uploadContinueLoading: state.uploadContinueLoading
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
