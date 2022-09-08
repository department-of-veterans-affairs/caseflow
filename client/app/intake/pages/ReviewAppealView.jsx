import React, { useContext } from 'react';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import { formatDateStr } from '../../util/DateUtil';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import { css, target } from 'glamor';
import TextareaField from '../../components/TextareaField';
// import { reason, setOtherReason, otherReason, selectedIssues, setSelectedIssues } from '../pages/SplitAppealView';
import CaseHearingsDetail from '../../queue/CaseHearingsDetail';
import _ from 'lodash';

// const issueListStyling = css({ marginTop: '0rem', marginLeft: '6rem' });

const styles = {
  mainTable: css({
    '& .bolded-header': {
      fontWeight: 'bold',
    },
    '& tr > td': {
      width: '0%',
      verticalAlign: 'initial',
    },
    '& tr > td > ol > li > p': {
      marginTop: '20px !important',
      marginBottom: '0px !important',
      lineHeight: '0.5em',
    },
    '&': {
      margin: 0,
    },
    '& td:first-child': {
      paddingLeft: '1%',
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
  const requestIssues = serverIntake.requestIssues;
  const streamdocketNumber = props.appeal.stream_docket_number;

  const reviewOpt = _.startCase(serverIntake?.docketType?.split('_').join(' '));
  const { selectedIssues, reason, otherReason } = useContext(StateContext);
  const veteran = serverIntake.veteran.name;
  const claimantName = props.serverIntake.claimantName;
  const receiptDate = props.serverIntake.receiptDate;

  // const { serverIntake } = props;
  // const { reason, setOtherReason, otherReason, selectedIssues, setSelectedIssues } = useContext(StateContext);

  // const streamdocketNumber = props.appeal.stream_docket_number;

  // const requestIssues = props.serverIntake.requestIssues;
  // const docketType = props.serverIntake.docketType;
  // const reviewOpt = _.startCase(serverIntake?.docketType?.split('-').join(' '));
  // const original_hearing_request_type = props.appeal.original_hearing_request_type;


  // const onIssueChange = (evt) => {
  //   setSelectedIssues({ ...selectedIssues, [evt.target.name]: evt.target.labels[0].innerText });
  // };

  // const onOtherReasonChange = (otherReason) => {
  //   setOtherReason(otherReason);
  // };

  // {console.log(JSON.stringify(CaseHearingsDetail))}

  return (
    <>
      <div>
        <h1 style={{ margin: '0px' }}>{COPY.SPLIT_APPEAL_REVIEW_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_REVIEW_SUBHEAD}</span>
      </div> &ensp;
      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'left' }}>
        <u style={{fontSize: '20px' }}>{COPY.SPLIT_APPEAL_REVIEW_REASONING_TITLE}</u> &ensp;
        <span style={{ flexBasis: '75%', fontSize: '20px' }}>{reason}</span>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'left' }}>
        {otherReason}
      </div>
      <br />

      <br />
      <section className={styles.tableSection}>
        <table className={`usa-table-borderless ${styles.mainTable}`}>
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
            <td>{reviewOpt}
              <div>
                {/* {original_hearing_request_type} */}
              </div>
              <div>
                {receiptDate}
              </div>
            </td>
            <td>"View hearing worksheet link"</td>
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
                <li>{selectedIssues.selectValue.value}</li>
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
export default ReviewAppealView;
