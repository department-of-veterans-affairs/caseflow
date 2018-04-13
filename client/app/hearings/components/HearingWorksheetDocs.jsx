import React, { Component } from 'react';
import { connect } from 'react-redux';
import { formatDate, formatArrayOfDateStrings } from '../../util/DateUtil';

class HearingWorksheetDocs extends Component {

  render() {

    let { worksheet, worksheetAppeals } = this.props;

    return <div className="cf-hearings-worksheet-data">
      {!this.props.print &&
      <div>
        <h2 className="cf-hearings-worksheet-header">Relevant Documents</h2>
        <h4>Docs in Claims Folder: {worksheet.cached_number_of_documents}</h4>
      </div>
      }
      {this.props.print &&
      <div>
        <h2 className="cf-hearings-print-worksheet-header">Relevant Documents</h2>
        <h4 className="cf-hearings-doc-print-worksheet-header">
      Docs in Claims Folder: {worksheet.cached_number_of_documents}
        </h4>
      </div>
      }

      {Object.values(worksheetAppeals).map((appeal, key) => {

        let notCertified = !appeal.certification_date;

        return <div key={appeal.id} id={appeal.id}><div>
          {!this.props.print &&
            <p className="cf-appeal-stream-label">
              APPEAL STREAM <span>{key + 1}</span>
              {appeal.contested_claim && <span className="cf-red-text"> CC</span>}
            </p>
          }
          {this.props.print &&
            <p className="cf-hearings-print-appeal-stream">APPEAL STREAM <span>{key + 1}</span></p>
          }
        </div>
        <div>
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>Docket Number:</div>
            <div>{appeal.docket_number}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>Prior BVA Decision:</div>
            <div>{formatDate(appeal.prior_decision_date)}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>NOD:</div>
            <div>{formatDate(appeal.nod_date)}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>SOC:</div>
            <div>{formatDate(appeal.soc_date)}</div>
          </div>

        </div>
        <div>
          <div className="cf-hearings-worksheet-data-cell column-1">
            <div>Form 9:</div>
            <div>{formatDate(appeal.form9_date)}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-2">
            <div>SSOC:</div>
            <div>{formatArrayOfDateStrings(appeal.ssoc_dates)}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-3">
            <div>Certification:</div>
            <div> {notCertified ? <span>Not certified</span> : formatDate(appeal.certification_date)}</div>
          </div>
          <div className="cf-hearings-worksheet-data-cell column-4">
            <div>Docs since Certification:</div>
            <div>{appeal.cached_number_of_documents_after_certification}</div>
          </div>
          <div className="cf-hearings-divider"></div>
        </div>
        </div>;
      })}
    </div>;
  }
}

// TODO map state to corresponding stream
export default connect()(HearingWorksheetDocs);
