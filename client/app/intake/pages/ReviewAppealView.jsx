import React, { useContext } from 'react';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import { css, target } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const styles = {
  mainTable: css({
    '& .bolded-header': {
      fontWeight: 'bold',
    },
    '& tr > td': {
      width: '.5%',
      verticalAlign: 'left',
    },
    '& tr > td > ol > li > p': {
      marginTop: '0px !important',
      paddingBottom: '20px',
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
      //Test border: '1px solid #E2E3E4',
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
  }),
  tableSection: css({
    marginBottom: '40px',
    marginTop: '40px'
  })
};

const ReviewAppealView = (props) => {
  const { serverIntake } = props;
  const { reason, setOtherReason, otherReason, selectedIssues, setSelectedIssues } = useContext(StateContext);
  const veteran = serverIntake.veteran.name;
  const streamdocketNumber = props.appeal.stream_docket_number;
  const claimantName = props.serverIntake.claimantName;
  const requestIssues = props.serverIntake.requestIssues;
  const docketType = props.serverIntake.docketType;
  const original_hearing_request_type = props.appeal.original_hearing_request_type;
  const receiptDate = props.serverIntake.receiptDate;
  const hearings = props.hearings;
  {console.log(JSON.stringify(props.hearings[0].disposition))}

  const onIssueChange = (evt) => {
    setSelectedIssues({ ...selectedIssues, [evt.target.name]: evt.target.labels[0].innerText });
  };

  const onOtherReasonChange = (otherReason) => {
    setOtherReason(otherReason);
  };

  return (
    <>
      <div>
        <h1 style={{ margin: '0px' }}>{COPY.SPLIT_APPEAL_REVIEW_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_REVIEW_SUBHEAD}</span>
      </div> &ensp;
      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'left' }}>
        <u>{COPY.SPLIT_APPEAL_REVIEW_REASONING_TITLE}</u> &ensp;
        <span style={{ flexBasis: '75%' }}>{reason} &ensp; {otherReason}</span>
      </div>
      <br />
      <br />
      <br />
      <section className={styles.tableSection}>
        <table className={`usa-table-borderless ${styles.mainTable}`}>
          <tr>
            <th></th>
            <th className="bolded-header"> {COPY.TABLE_ORIGINAL_APPEAL}</th>
            <th className="bolded-header"> {COPY.TABLE_NEW_APPEAL} </th>
          </tr>
          <tr>
            <td><em>{ claimantName ? COPY.APPELLANT : COPY.TABLE_VETERAN}</em></td>
            <td>{claimantName ? claimantName : veteran }</td>
            <td>{claimantName ? claimantName : veteran }</td>
          </tr>
          {serverIntake.veteranIsNotClaimant ?
            <>
              <tr>
                <td><em>{COPY.APPELLANT }</em></td>
                <td>{claimantName }</td>
                <td>{claimantName }</td>
              </tr>
              <tr>
                <td><em>{ COPY.TABLE_VETERAN}</em></td>
                <td>{ veteran}</td>
                <td>{ veteran}</td>
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
            <td>
              <div>
                {docketType}
              </div>
              <div>
                {original_hearing_request_type}
              </div>
              <div>
                {receiptDate}
              </div>
              <div>
                { JSON.stringify(props.hearings[0].disposition) }
              </div>
              <div>
                <Link
                  rel="noopener"
                  target="_blank"
                  href={`/hearings/worksheet/print?keep_open=true&hearing_ids=${hearings[0].uuid}`}>
                  {COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY}
                </Link>
              </div>
            </td>
            <td>
            <div>
                {docketType}
              </div>
              <div>
                {original_hearing_request_type}
              </div>
              <div>
                {receiptDate}
              </div>
              <div>
                { JSON.stringify(props.hearings[0].disposition) }
              </div>
              <div>
                <Link
                  rel="noopener"
                  target="_blank"
                  href={`/hearings/worksheet/print?keep_open=true&hearing_ids=${hearings[0].uuid}`}>
                  {COPY.CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY}
                </Link>
              </div>
            </td>
          </tr>
          <tr>
            <td><em>{COPY.TABLE_ISSUE}</em></td>
            <td>
              <ol>
                {requestIssues.map((issue) => {
                  return (
                    <li>
                      <p>{issue.description}</p>
                      <p>Benefit type: {issue.benefit_type}</p>
                      <p>Decision date: {issue.approx_decision_date}</p>
                    </li>
                  );
                })}
              </ol>
            </td>
            <td>
              <ol>
                {Object.keys(selectedIssues).map((issueKey) => <li key={issueKey}>{selectedIssues[issueKey]}</li>)}
              </ol>
            </td>
          </tr>
        </table>
      </section>
    </>
  );
};

ReviewAppealView.propTypes = {
  serverIntake: PropTypes.object
};
export default (ReviewAppealView);
