import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

export class BuildSchedule extends React.Component {

  render() {
    return <AppSegment filledBackground>
      <h1>Welcome to Caseflow Hearing Schedule!</h1>
      <h2>Build Schedule</h2>
      <p>To build the schedule, please download one of the templates and fill it with the appropriate data. Then,
        click the "Upload files" button to import your completed .xlsx file.</p>
    </AppSegment>;
  }
}

export default BuildSchedule;
