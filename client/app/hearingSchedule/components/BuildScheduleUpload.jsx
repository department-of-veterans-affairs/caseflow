import React from 'react';
import COPY from '../../../COPY.json';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import RadioField from '../../components/RadioField';
import UploadDateSelector from './UploadDateSelector';
import { SPREADSHEET_TYPES } from '../constants';

export default class BuildScheduleUpload extends React.Component {

  getRoCoDisplay = () => {
    return <div>{ SPREADSHEET_TYPES.RoSchedulePeriod.display }
      { this.props.fileType === SPREADSHEET_TYPES.RoSchedulePeriod.value &&
      <UploadDateSelector
        startDate={this.props.roCoStartDate}
        endDate={this.props.roCoEndDate}
        onStartDateChange={this.props.onRoCoStartDateChange}
        onEndDateChange={this.props.onRoCoEndDateChange}
      /> }
    </div>;
  };

  getJudgeDisplay = () => {
    return <div>{ SPREADSHEET_TYPES.JudgeSchedulePeriod.display }
      { this.props.fileType === SPREADSHEET_TYPES.JudgeSchedulePeriod.value &&
      <UploadDateSelector
        startDate={this.props.judgeStartDate}
        endDate={this.props.judgeEndDate}
        onStartDateChange={this.props.onJudgeStartDateChange}
        onEndDateChange={this.props.onJudgeEndDateChange}
      /> }
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
  judgeStartDate: PropTypes.string,
  judgeEndDate: PropTypes.string,
  onJudgeStartDateChange: PropTypes.func,
  onJudgeEndDateChange: PropTypes.func
};
