import React from 'react';
import COPY from '../../../COPY.json';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import RadioField from '../../components/RadioField';

const fileTypes = [
  {
    value: 'ro/co',
    displayText: <div>RO and CO hearings</div>
  },
  {
    value: 'judge',
    displayText: <div>Judge non-availability</div>
  }
];

export default class BuildScheduleUpload extends React.Component {
  render() {
    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_UPLOAD_PAGE_HEADER}</h1>
      <p>{COPY.HEARING_SCHEDULE_UPLOAD_PAGE_INSTRUCTIONS}</p>
      <div className="cf-help-divider"></div>
      <RadioField
        name={COPY.HEARING_SCHEDULE_UPLOAD_PAGE_SUB_HEADER}
        options={fileTypes}
        value={this.props.fileType}
        onChange={this.props.onFileTypeChange}
        required
        vertical
        strongLabel
      />
    </AppSegment>;
  }
}

BuildScheduleUpload.propTypes = {
  fileType: PropTypes.string,
  onFileTypeChange: PropTypes.func
};