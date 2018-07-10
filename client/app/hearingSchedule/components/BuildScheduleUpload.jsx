import React from 'react';
import COPY from '../../../COPY.json';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import RadioField from '../../components/RadioField';
import BasicDateRangeSelector from '../../components/BasicDateRangeSelector';
import FileUpload from '../../components/FileUpload';
import InlineForm from '../../components/InlineForm';
import { SPREADSHEET_TYPES } from '../constants';

const fileUploadStyling = css({
  marginTop: '70px'
});

export default class BuildScheduleUpload extends React.Component {

  getRoCoDisplay = () => {
    return <div>{ SPREADSHEET_TYPES.RoSchedulePeriod.display }
      { this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value &&
      <InlineForm>
        <BasicDateRangeSelector
          startDateName="startDate"
          startDateValue={this.props.roCoStartDate}
          startDateLabel={false}
          endDateName="endDate"
          endDateValue={this.props.roCoEndDate}
          endDateLabel={false}
          onStartDateChange={this.props.onRoCoStartDateChange}
          onEndDateChange={this.props.onRoCoEndDateChange}
        />
        <div {...fileUploadStyling} >
          <FileUpload {...fileUploadStyling}
            preUploadText="Select a file for upload"
            postUploadText="Choose a different file"
            id="ro_co_file_upload"
            onChange={this.props.onRoCoFileUpload}
            value={this.props.roCoFileUpload}
          />
        </div>
      </InlineForm> }
    </div>;
  };

  getJudgeDisplay = () => {
    return <div>{ SPREADSHEET_TYPES.JudgeSchedulePeriod.display }
      { this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value &&
      <InlineForm>
        <BasicDateRangeSelector
          startDateName="startDate"
          startDateValue={this.props.judgeStartDate}
          startDateLabel={false}
          endDateName="endDate"
          endDateValue={this.props.judgeEndDate}
          endDateLabel={false}
          onStartDateChange={this.props.onJudgeStartDateChange}
          onEndDateChange={this.props.onJudgeEndDateChange}
        />
        <div {...fileUploadStyling} >
          <FileUpload
            preUploadText="Select a file for upload"
            postUploadText="Choose a different file"
            id="judge_file_upload"
            onChange={this.props.onJudgeFileUpload}
            value={this.props.judgeFileUpload}
          />
        </div>
      </InlineForm>}
    </div>;
  };

  render() {
    const fileTypes = [
      {
        value: SPREADSHEET_TYPES.RoSchedulePeriod.value,
        displayText: this.getRoCoDisplay()
      },
      {
        value: SPREADSHEET_TYPES.JudgeSchedulePeriod.value,
        displayText: this.getJudgeDisplay()
      }
    ];

    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_UPLOAD_PAGE_HEADER}</h1>
      <p>{COPY.HEARING_SCHEDULE_UPLOAD_PAGE_INSTRUCTIONS}</p>
      <div className="cf-help-divider"></div>
      <RadioField
        name={COPY.HEARING_SCHEDULE_UPLOAD_PAGE_RADIO_FIELD_HEADER}
        options={fileTypes}
        value={this.props.fileType}
        onChange={this.props.onFileTypeChange}
        required
        vertical
        strongLabel
      />
      <Link
        name="cancel"
        to="/hearings/schedule/build">
        Cancel
      </Link>
      <div className="cf-push-right">
        <Link
          name="continue"
          button="primary"
          to="/hearings/schedule/build/upload">
          Continue
        </Link>
      </div>
    </AppSegment>;
  }
}

BuildScheduleUpload.propTypes = {
  fileType: PropTypes.string,
  onFileTypeChange: PropTypes.func,
  roCoStartDate: PropTypes.string,
  roCoEndDate: PropTypes.string,
  onRoCoStartDateChange: PropTypes.func,
  onRoCoEndDateChange: PropTypes.func,
  roCoFileUpload: PropTypes.string,
  onRoCoFileUpload: PropTypes.func,
  judgeStartDate: PropTypes.string,
  judgeEndDate: PropTypes.string,
  onJudgeStartDateChange: PropTypes.func,
  onJudgeEndDateChange: PropTypes.func,
  judgeFileUpload: PropTypes.string,
  onJudgeFileUpload: PropTypes.func
};
