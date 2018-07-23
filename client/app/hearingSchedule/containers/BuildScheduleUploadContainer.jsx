import React from 'react';
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
  toggleUploadContinueLoading
} from '../actions';
import BuildScheduleUpload from '../components/BuildScheduleUpload';

export class BuildScheduleUploadContainer extends React.Component {

  validateData = () => {
    if (this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      return this.props.roCoStartDate && this.props.roCoEndDate && this.props.roCoFileUpload;
    }
    if (this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      return this.props.judgeStartDate && this.props.judgeEndDate && this.props.judgeFileUpload;
    }

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
        this.props.history.push(`/schedule/build/upload/${response.body.id}`);
      }, (err) => {
      }
    );
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
  toggleUploadContinueLoading
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(BuildScheduleUploadContainer));
