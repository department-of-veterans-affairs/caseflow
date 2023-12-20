import _ from 'lodash';
import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import DOMPurify from 'dompurify';
import WorksheetFooter from './WorksheetFooter';
import WorksheetHeader from './WorksheetHeader';
import HearingWorksheetPreImpressions from './HearingWorksheetPreImpressions';
import { getWorksheetTitle } from './HearingWorksheet';
import BENEFIT_TYPES from '../../../../constants/BENEFIT_TYPES';
import { filterCurrentIssues, filterIssuesOnAppeal } from '../../utils';
import { formatDateStr, formatArrayOfDateStrings } from '../../../util/DateUtil';
import { formatNameShort } from '../../../util/FormatUtil';
import { openPrintDialogue } from '../../../util/PrintUtil';
import querystring from 'querystring';

const getLegacyHearingWorksheetDocsSection = (appeal) => {
  return (
    <div className="cf-hearings-worksheet-data">
      <div className="cf-hearings-worksheet-data-cell">
        <h4>Prior BVA Deci.</h4>
        <div className="cf-hearings-headers">{formatDateStr(appeal.prior_bva_decision_date)}</div>
      </div>
      <div className="cf-hearings-worksheet-data-cell">
        <h4>NOD</h4>
        <div className="cf-hearings-headers">{formatDateStr(appeal.nod_date)}</div>
      </div>
      <div className="cf-hearings-worksheet-data-cell">
        <h4>SOC</h4>
        <div className="cf-hearings-headers">{formatDateStr(appeal.soc_date)}</div>
      </div>
      <div className="cf-hearings-worksheet-data-cell">
        <h4>Form 9</h4>
        <div className="cf-hearings-headers">{formatDateStr(appeal.form9_date)}</div>
      </div>
      <div className="cf-hearings-worksheet-data-cell">
        <h4>SSOC</h4>
        <div className="cf-hearings-headers">{formatArrayOfDateStrings(appeal.ssoc_dates)}</div>
      </div>
      <div className="cf-hearings-worksheet-data-cell">
        <h4>Certification</h4>
        <div className="cf-hearings-headers">
          {appeal.certification_date ? formatDateStr(appeal.certification_date) : 'Not certified'}
        </div>
      </div>
      <div className="cf-hearings-worksheet-data-cell double">
        <h4>Docs since Cert.</h4>
        <div className="cf-hearings-headers">{appeal.cached_number_of_documents_after_certification}</div>
      </div>
    </div>
  );
};

export class HearingWorksheetPrinted extends React.Component {

  componentDidMount() {
    const { worksheet, updateTitle } = this.props;

    if (updateTitle) {
      document.title = getWorksheetTitle(worksheet);
    }

    const queryString = querystring.parse(window.location.search.slice(1));

    if (!queryString.keep_open) {
      window.onafterprint = () => window.close();

      openPrintDialogue();
    }
  }

  isLegacy() {
    const { worksheet } = this.props;

    return worksheet.docket_name === 'legacy';
  }

  getHearingWorksheetIssuesSection(appeal) {
    const { worksheetIssues } = this.props;
    const currentIssues = appeal ?
      filterCurrentIssues(filterIssuesOnAppeal(worksheetIssues, appeal.id)) :
      worksheetIssues;

    if (_.isEmpty(currentIssues)) {
      return;
    }

    return (
      <div>
        <h4>Issues</h4>
        {
          Object.values(currentIssues).
            map((issue, key) => (
              <div className="cf-hearing-worksheet-issues-wrapper" key={key}>
                {
                  !this.isLegacy() &&
                <div className="cf-hearing-worksheet-issue-field cf-hearing-worksheet-issue-benefit-type">
                  <h4>Benefit</h4>
                  <p>{BENEFIT_TYPES[issue.program]}</p>
                </div>
                }
                {
                  !this.isLegacy() &&
                <div className="cf-hearing-worksheet-issue-field cf-hearing-worksheet-issue-diagnostic-code">
                  <h4>Diagnostic</h4>
                  <p>{issue.diagnostic_code}</p>
                </div>
                }
                {
                  !this.isLegacy() &&
                <div className="cf-hearing-worksheet-issue-field cf-hearing-worksheet-issue-disposition">
                  <h4>Disp.</h4>
                  <p>{issue.disposition}</p>
                </div>
                }
                <div className="cf-hearing-worksheet-issue-field cf-hearing-worksheet-issue-description">
                  <h4>Description</h4>
                  <p>{issue.description}</p>
                </div>
                {
                  this.isLegacy() &&
                <div className="cf-hearing-worksheet-issue-field cf-hearing-worksheet-issue-legacy-disposition">
                  <h4>Disp.</h4>
                  <p>{issue.disposition}</p>
                </div>
                }
                {
                  issue.notes &&
                <div className="cf-hearing-worksheet-issue-field">
                  <h4>Notes</h4>
                  <p>{issue.notes}</p>
                </div>
                }
                {
                  !this.isLegacy() && issue.worksheet_notes &&
                <div className="cf-hearing-worksheet-issue-field">
                  <h4>Worksheet Notes</h4>
                  <p>{issue.worksheet_notes}</p>
                </div>
                }
                <HearingWorksheetPreImpressions issue={issue} print />
              </div>
            ))
        }
      </div>
    );
  }

  getLegacyHearingSection() {
    const { worksheetAppeals } = this.props;

    return (
      <div>
        {
          Object.values(worksheetAppeals).map((appeal, key) => (
            <div key={key} className="cf-hearings-appeal-procedural-history">
              <h4>Procedural History</h4>
              <h4 className="cf-txt-r">
                Appeal Stream {key + 1} - Docket #{appeal.docket_number}
                {appeal.contested_claim && '  CC'}
                {appeal.dic && '  DIC'}
              </h4>
              {getLegacyHearingWorksheetDocsSection(appeal)}
              {this.getHearingWorksheetIssuesSection(appeal)}
            </div>
          ))
        }
      </div>
    );
  }

  render() {
    const { worksheet, worksheetIssues } = this.props;

    // Putting the footer in a thead tag is a workaround to get the footer
    // to display on each respective page. This also requires a table to wrap it,
    // otherwise react will throw a bunch of warnings.
    return (
      <table>
        <thead>
          <tr>
            <td>
              <WorksheetFooter
                veteranName={formatNameShort(worksheet.veteran_first_name, worksheet.veteran_last_name)}
              />
            </td>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>
              <WorksheetHeader worksheet={worksheet} print />
              {this.isLegacy() && this.getLegacyHearingSection()}
              {
                !this.isLegacy() && !_.isEmpty(worksheetIssues) &&
                <div className="cf-hearings-all-issues-wrapper">
                  {this.getHearingWorksheetIssuesSection()}
                </div>
              }
              <div className="cf-hearings-worksheet-form" id="cf-hearings-worksheet-summary">
                <div className="cf-hearings-worksheet-data">
                  <label>Hearing Summary</label>
                  <div
                    dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(worksheet.summary).replace(/\r|\n/g, '') }}
                  />
                </div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    );
  }
}

HearingWorksheetPrinted.propTypes = {
  worksheet: PropTypes.object,
  worksheetAppeals: PropTypes.object,
  worksheetIssues: PropTypes.object,
  updateTitle: PropTypes.bool
};

HearingWorksheetPrinted.defaultProps = {
  updateTitle: true
};

const mapStateToProps = (state, ownProps) => ({
  worksheet: ownProps.worksheet || state.hearingWorksheet.worksheet,
  worksheetAppeals: ownProps.worksheetAppeals || state.hearingWorksheet.worksheetAppeals,
  worksheetIssues: ownProps.worksheetIssues || state.hearingWorksheet.worksheetIssues
});

export default connect(mapStateToProps)(HearingWorksheetPrinted);
