import React from 'react';
import { Component } from 'react';
import HearingWorksheetIssues from '/HearingWorksheetIssues';

export default class HearingWorksheetStream extends Component {

  render() {
    // Todo <HearingWorksheetIssues />
    return <div>
         <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Issues</h2>
          <HearingWorksheetIssues />
          <p className="cf-appeal-stream-label">APPEAL STREAM XX</p>
        </div>
    </div>;
  }
}
