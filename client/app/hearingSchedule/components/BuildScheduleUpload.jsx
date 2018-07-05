import React from 'react';
import COPY from '../../../COPY.json';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import RadioField from '../../components/RadioField';
import UploadDateSelector from './UploadDateSelector';

export default class BuildScheduleUpload extends React.Component {

  getRoCoDisplay = () => {
    if (this.props.fileType === 'ro/co') {
      return <div>RO and CO hearings
        <UploadDateSelector
          startDate={this.props.roCoStartDate}
          endDate={this.props.roCoEndDate}
          onStartDateChange={this.props.onRoCoStartDateChange}
          onEndDateChange={this.props.onRoCoEndDateChange}
        />
      </div>;
    }

    return <div>RO and CO hearings</div>;
  };

  getJudgeDisplay = () => {
    if (this.props.fileType === 'judge') {
      return <div>Judge non-availability
        <UploadDateSelector
          startDate={this.props.judgeStartDate}
          endDate={this.props.judgeEndDate}
          onStartDateChange={this.props.onJudgeStartDateChange}
          onEndDateChange={this.props.onJudgeEndDateChange}
        />
      </div>;
    }

    return <div>Judge non-availability</div>;
  };

  render() {

    const fileTypes = [
      {
        value: 'ro/co',
        displayText: this.getRoCoDisplay()
      },
      {
        value: 'judge',
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
