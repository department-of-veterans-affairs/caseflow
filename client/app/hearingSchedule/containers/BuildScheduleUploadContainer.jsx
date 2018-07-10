import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import ApiUtil from '../../util/ApiUtil';
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

  getData = () => {
    return ApiUtil.convertToSnakeCase({
      schedulePeriod: {
        fileName: 'this is a fake file name',
        startDate: '2015/10/24',
        endDate: '2016/10/24',
        type: 'RoSchedulePeriod'
      }
    });
  };

  createSchedulePeriod = () => {
    const data = this.getData();

    ApiUtil.post('/hearings/schedule_periods', { data }).
      then();
  };

  onUploadContinue = () => {
    this.props.toggleUploadContinueLoading();
    this.createSchedulePeriod();
    this.props.toggleUploadContinueLoading();
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

export default connect(mapStateToProps, mapDispatchToProps)(BuildScheduleUploadContainer);
