import React, { useContext } from 'react';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import { DateString } from '../../util/DateUtil';
import { css } from 'glamor';
import _ from 'lodash';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { ExternalLinkIcon } from '../../components/icons';

const styles = {
  mainTable: css({
    '& .bolded-header': {
      fontWeight: 'bold',
    },
    '& tr > td': {
      width: '0.5%',
      verticalAlign: 'left',
    },
    '& tr > td > ol > li > p': {
      marginTop: '0px !important',
      marginBottom: '20px !important',
      lineHeight: '0.5em',
    },
    '&': {
      margin: 0,
    },
    '& td:first-child': {
      paddingLeft: '3%',
    },
    '& tr:first-of-type td': {
      borderTop: 'none',
    },
    '& tr:last-of-type td': {
      paddingBottom: '20px',
      borderBottom: '0px solid #9999',
    },
    '& tr > th': {
      borderTop: 'none',
      // border: '1px solid #E2E3E4',
    },
    '& ol': {
      paddingLeft: '0.94em !important',
    },
    '& tr > td:last-of-type': {
      borderLeft: '1px solid #979797',
      paddingLeft: '3%',
    },
    '& tr > th:last-of-type': {
      borderLeft: '1px solid #979797',
      paddingLeft: '3%',
    },
    '& p': {
      marginTop: '1.5rem',
      marginBottom: '1.5rem',
    },
    '& .hearing_view p': {
      marginTop: '0.1rem',
      marginBottom: '0.1rem',
    },
    '& g': {
      fill: '#0071bc !important',
    },
    '& .info': {
      textDecoration: 'underline',
    },
    '& .text_info': {
      lineHeight: '1.3em !important',
    }
  }),
  tableSection: css({
    marginBottom: '40px',
    marginTop: '40px'
  })
};

const ReviewAppealView = (props) => {
  const { serverIntake } = props;
  const requestIssues = serverIntake.requestIssues;
  const streamdocketNumber = props.appeal.stream_docket_number;
  const reviewOpt = _.startCase(serverIntake?.docketType?.split('_').join(' '));
  const { selectedIssues, reason, otherReason } = useContext(StateContext);
  const veteran = serverIntake.veteran.name;
  const claimantName = props.serverIntake.claimantName;
  const hearings = props.hearings;
  const hearingsSize = hearings.length;
  const originalHearingRequestType = _.startCase(props.appeal.original_hearing_request_type);
  const PARSE_INT_RADIX = 10;
  const hearingDayDate = props.hearingDayDate;
  const currentValues = {
    reason,
    otherReason,
    selectedIssues
  };

  if (Object.keys(selectedIssues).length > 0) {
    localStorage.setItem('myValues', JSON.stringify(currentValues));
  }

  const myValues = JSON.parse(localStorage.getItem('myValues'));
  let selectElement = [];

  Object.keys(myValues.selectedIssues).map((key) => {
    for (let currentItem in requestIssues) {
      if (requestIssues[currentItem].id === parseInt(key, PARSE_INT_RADIX) && (myValues.selectedIssues[key] === true)) {
        selectElement = [requestIssues[currentItem], ...selectElement];
      }
    }

    return selectElement;
  });
  let selectOriginal = requestIssues;

  Object.keys(myValues.selectedIssues).map((key) => {
    for (let currentItem in requestIssues) {
      if (requestIssues[currentItem].id === parseInt(key, PARSE_INT_RADIX) && (myValues.selectedIssues[key] === true)) {
        selectOriginal.splice(currentItem, 1);
      }
    }

    return selectOriginal;
  });

  return (
    <>
      <div>
        <h1 style={{ margin: '0px' }}>{COPY.SPLIT_APPEAL_REVIEW_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_REVIEW_SUBHEAD}</span>
      </div> &ensp;
      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'left' }}>
        <u style={{ fontSize: '20px' }}>{COPY.SPLIT_APPEAL_REVIEW_REASONING_TITLE}</u> &ensp;
        <span style={{ flexBasis: '75%' }}>{myValues.reason} &ensp; {myValues.otherReason}</span>
      </div>
      <br />
      <br />
      <br />
      <section className={styles.tableSection}>
        <table className={`usa-table-borderless ${styles.mainTable}`} id="review_table">
          <tr>
            <th></th>
            <th className="bolded-header"> {COPY.TABLE_ORIGINAL_APPEAL}</th>
            <th className="bolded-header"> {COPY.TABLE_NEW_APPEAL} </th>
          </tr>
          {serverIntake.veteranIsNotClaimant ?
            <>
              <tr>
                <td><em>{ COPY.TABLE_VETERAN}</em></td>
                <td>{ veteran}</td>
                <td>{ veteran}</td>
              </tr>
              <tr>
                <td><em>{COPY.APPELLANT }</em></td>
                <td>{claimantName }</td>
                <td>{claimantName }</td>
              </tr>
            </> :
            <tr>
              <td><em>{ COPY.TABLE_VETERAN}</em></td>
              <td>{ veteran }</td>
              <td>{ veteran }</td>
            </tr>
          }

          <tr>
            <td><em>{COPY.TABLE_DOCKET_NUMBER}</em></td>
            <td>{streamdocketNumber}</td>
            <td>{streamdocketNumber}</td>
          </tr>
          <tr>
            <td><em>{COPY.TABLE_REVIEW_OPTION}</em></td>
            <td className="hearing_view">
              {(originalHearingRequestType.trim().length === 0) ?
                <p>{reviewOpt}</p> :
                <p>{reviewOpt} - { originalHearingRequestType }</p>}
              {(hearingsSize > 0 &&
                hearings[0].disposition !== null
              ) &&
                <>
                  <p><DateString date={hearingDayDate} dateFormat="MM/DD/YYYY" /></p>
                  <p> { _.startCase(hearings[0].disposition) } </p>
                  <Link
                    rel="noopener"
                    target="_blank"
                    href={`/hearings/worksheet/print?keep_open=true&hearing_ids=${hearings[0].uuid}`}>
                    {COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY}
                  </Link> <ExternalLinkIcon />
                </>
              }
            </td>
            <td className="hearing_view">
              {(originalHearingRequestType.trim().length === 0) ?
                <p>{reviewOpt}</p> :
                <p>{reviewOpt} - { originalHearingRequestType }</p>}
              {(hearingsSize > 0 &&
                hearings[0].disposition !== null
              ) &&
                <>
                  <p><DateString date={hearingDayDate} dateFormat="MM/DD/YYYY" /></p>
                  <p> { _.startCase(hearings[0].disposition) } </p>
                  <Link
                    rel="noopener"
                    target="_blank"
                    href={`/hearings/worksheet/print?keep_open=true&hearing_ids=${hearings[0].uuid}`}>
                    {COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY}
                  </Link> <ExternalLinkIcon />
                </>
              }
            </td>
          </tr>
          <tr>
            <td><em>{COPY.TABLE_ISSUE}</em></td>
            <td>
              <ol>
                {selectOriginal.map((issue) => {
                  return (
                    <li>
                      <p><span className="text_info">{issue.description}</span></p>
                      <p><span className="info">Benefit type:</span>  {_.startCase(issue.benefit_type)}</p>
                      <p><span className="info">Decision date:</span>
                        <DateString date={issue.approx_decision_date} dateFormat="MM/DD/YYYY" /></p>
                    </li>
                  );
                })}
              </ol>
            </td>
            <td>
              <ol>
                {selectElement.map((issue) => {
                  return (
                    <li>
                      <p><span className="text_info">{issue.description}</span></p>
                      <p><span className="info">Benefit type:</span> {_.startCase(issue.benefit_type)}</p>
                      <p><span className="info">Decision date:</span>
                        <DateString date={issue.approx_decision_date} dateFormat="MM/DD/YYYY" /></p>
                    </li>
                  );
                })}
              </ol>
            </td>
          </tr>
        </table>
      </section>
    </>
  );
};

ReviewAppealView.propTypes = {
  serverIntake: PropTypes.object,
  appeal: PropTypes.array,
  hearings: PropTypes.array,
  hearingDayDate: PropTypes.string,
};
export default (ReviewAppealView);
