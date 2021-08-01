import React, { useEffect, useState } from 'react';
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
import { ReviewAssignments } from '../components/ReviewAssignments';

export const BuildScheduleUploadContainer = (props) => {
  const [assignments, setAssignments] = useState(false);

  useEffect(() => {
    return () => props.unsetUploadErrors();
  }, []);

  const validateDatesAndFile = (onFailure, file, startDate, endDate) => {
    if ((!startDate && !endDate && props.fileType !== SPREADSHEET_TYPES.JudgeSchedulePeriod.value) || !file) {
      onFailure(['Please make sure all required fields are filled in.']);

      return false;
    }
    if (endDate < startDate && props.fileType !== SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      onFailure(['The end date must be after the start date.']);

      return false;
    }

    return true;
  };

  const validateData = () => {
    if (props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      return validateDatesAndFile(
        props.updateRoCoUploadFormErrors,
        props.roCoFileUpload,
        props.roCoStartDate,
        props.roCoEndDate,
      );
    }
    if (props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      return validateDatesAndFile(
        props.updateJudgeUploadFormErrors,
        props.judgeFileUpload
      );
    }
    props.updateUploadFormErrors('Please select a file type.');

    return false;
  };

  const formatData = () => {
    let schedulePeriod = {};

    if (props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      schedulePeriod = {
        file: props.roCoFileUpload.file,
        startDate: props.roCoStartDate,
        endDate: props.roCoEndDate,
        type: props.fileType
      };
    }

    if (props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      schedulePeriod = {
        file: props.judgeFileUpload.file,
        type: props.fileType
      };
    }

    return ApiUtil.convertToSnakeCase(schedulePeriod);
  };

  const confirmJudgeAssignments = () => {
    const data = assignments.map((assignment) => ({
      hearing_day_id: assignment.id,
      judge_name: assignment.judgeName,
      judge_id: assignment.judgeId,
    }));

    ApiUtil.patch('/hearings/schedule_periods/confirm_judge_assignments', { data: { schedule_period: data } }).
      then(() => {
        props.history.push('/schedule');
      }).
      catch((error) => {
        console.error(error);
      });
  };

  const createSchedulePeriod = () => {
    props.toggleUploadContinueLoading();

    if (!validateData()) {
      props.toggleUploadContinueLoading();

      return;
    }

    const data = formatData();

    ApiUtil.post('/hearings/schedule_periods', { data: { schedule_period: data } }).
      then((response) => {
        props.toggleUploadContinueLoading();

        if (props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
          setAssignments(Object.values(ApiUtil.convertToCamelCase(response.body.hearing_days)));

          return;
        }

        props.history.push(`/schedule/build/upload/${response.body.id}`);
      }).
      catch(({ response }) => {
        // Map unspecified errors
        const errors = Array.isArray(response?.body?.errors) ?
          response.body.errors.map((error) => error.details) :
          ['ValidationError::UnspecifiedError'];

        // Display the errors based on the spreadsheet type
        if (props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
          props.updateRoCoUploadFormErrors(errors);
        } else if (props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
          props.updateJudgeUploadFormErrors(errors);
        }

        // Toggle the continue upload
        props.toggleUploadContinueLoading();
      });
  };

  return assignments ? (
    <ReviewAssignments
      onClickConfirmAssignments={confirmJudgeAssignments}
      onClickGoBack={() => setAssignments(false)}
      schedulePeriod={{
        type: props.fileType,
        hearingDays: assignments
      }}
    />
  ) : (
    <BuildScheduleUpload
      fileType={props.fileType}
      onFileTypeChange={props.onFileTypeChange}
      roCoStartDate={props.roCoStartDate}
      onRoCoStartDateChange={props.onRoCoStartDateChange}
      roCoEndDate={props.roCoEndDate}
      onRoCoEndDateChange={props.onRoCoEndDateChange}
      roCoFileUpload={props.roCoFileUpload}
      onRoCoFileUpload={props.onRoCoFileUpload}
      judgeStartDate={props.judgeStartDate}
      onJudgeStartDateChange={props.onJudgeStartDateChange}
      judgeEndDate={props.judgeEndDate}
      onJudgeEndDateChange={props.onJudgeEndDateChange}
      judgeFileUpload={props.judgeFileUpload}
      onJudgeFileUpload={props.onJudgeFileUpload}
      uploadFormErrors={props.uploadFormErrors}
      uploadRoCoFormErrors={props.uploadRoCoFormErrors}
      uploadJudgeFormErrors={props.uploadJudgeFormErrors}
      uploadContinueLoading={props.uploadContinueLoading}
      onUploadContinue={createSchedulePeriod}
    />

  );
};

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
