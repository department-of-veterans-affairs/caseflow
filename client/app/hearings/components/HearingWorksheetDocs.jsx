import React, { Component } from 'react';
import { connect } from 'react-redux';
import { formatDate, formatArrayOfDateStrings } from '../../util/DateUtil';

class HearingWorksheetDocs extends Component {

  render() {

    let { worksheet } = this.props;

    return <div className="cf-hearings-worksheet-data">
             <h2 className="cf-hearings-worksheet-header">Relevant Documents</h2>
             <h4>Docs in eFolder: {worksheet.cached_number_of_documents}</h4>

        {worksheet.appeals_ready_for_hearing.map((appeal, key) => {

          return <div key={appeal.id} id={appeal.id}><div>
                <p className="cf-appeal-stream-label">APPEAL STREAM <span>{key + 1}</span></p>
            </div>
              <div>
                <div className="cf-hearings-worksheet-data-cell column-1">
                    <div>Docket Number:</div>
                    <div>{appeal.docket_number}</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-2">
                    <div>NOD:</div>
                    <div>{formatDate(appeal.nod_date)}</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-3">
                    <div>Form 9:</div>
                    <div>{formatDate(appeal.form9_date)}</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-4">
                    <div>Prior BVA Decision:</div>
                    <div>{formatDate(appeal.prior_decision_date)}</div>
                </div>
                <div className="cf-hearings-worksheet-data-cell column-5">
                    <div>Docs since Certification:</div>
                    <div>{appeal.cached_number_of_documents_after_certification}</div>
                </div>
              </div>
                <div>
                    <div className="cf-hearings-worksheet-data-cell column-1">
                        <div>SOC:</div>
                        <div>{formatDate(appeal.soc_date)}</div>
                    </div>
                    <div className="cf-hearings-worksheet-data-cell column-2">
                        <div>Certification:</div>
                        <div>{formatDate(appeal.certification_date)}</div>
                    </div>
                    <div className="cf-hearings-worksheet-data-cell column-3">
                        <div>SSOC:</div>
                        <div>{formatArrayOfDateStrings(appeal.ssoc_dates)}</div>
                    </div>
                    <div className="cf-hearings-worksheet-data-cell column-4">
                        <div>&nbsp;</div>
                    </div>
                </div>
            </div>;
        })}


          </div>;
  }
}

// TODO map state to corresponding stream
export default connect()(HearingWorksheetDocs);
