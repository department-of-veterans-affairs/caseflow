import React, { Component } from 'react';
import { connect } from 'react-redux';

class HearingWorksheetDocs extends Component {

  render() {

    return <div className="cf-hearings-worksheet-data">
             <h2 className="cf-hearings-worksheet-header">Relevant Documents</h2>
             <h4>Docs in eFolder: 80</h4>
             <p className="cf-appeal-stream-label">APPEAL STREAM 1</p>
             <div className="cf-hearings-worksheet-data-Row">
                <div className="cf-hearings-worksheet-data-cell column-1">
                   <div>Docket Number:</div>
                   <div>69169169</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-2">
                   <div>NOD:</div>
                   <div>01/01/1990</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-3">
                   <div>Form 9:</div>
                   <div>01/01/1990</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-4">
                   <div>Prior BVA Decision:</div>
                   <div>01/01/1990</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-5">
                   <div>Docs since Certification:</div>
                   <div>23</div>
                </div>
             </div>
             <div className="cf-hearings-worksheet-data-Row">
                <div className="cf-hearings-worksheet-data-cell column-1">
                   <div>SOC:</div>
                   <div>01/01/1990</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-2">
                   <div>Certification:</div>
                   <div>01/01/1990</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-3">
                   <div>SSOC:</div>
                   <div>01/01/1990</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-4">
                   <div>&nbsp;</div>
                </div>
             </div>
          </div>;
  }
}

// TODO map state to corresponding stream
export default connect()(HearingWorksheetDocs);
