import React, { useState } from 'react';
import { css } from 'glamor';
import COPY from '../../../COPY';
import SPLIT_APPEAL_REASONS from '../../../constants/SPLIT_APPEAL_REASONS';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { formatDateStr } from '../../util/DateUtil';

const issueListStyling = css({ marginTop: '0rem', marginLeft: '6rem' });
const ReviewAppealView = (props) => {
  const { serverIntake } = props;
  const requestIssues = serverIntake.requestIssues;
  const [reason, setReason] = useState(null);
  const [otherReason, setOtherReason] = useState('');
  const [selectedIssues, setSelectedIssues] = useState({});
  const onIssueChange = (evt) => {
    setSelectedIssues({ ...selectedIssues, [evt.target.name]: evt.target.checked });
  };
  const onOtherReasonChange = (value) => {
    setOtherReason(value);
  };
  const reasonOptions = _.map(SPLIT_APPEAL_REASONS, (value) => ({
    label: value,
    value
  }));
  const issueOptions = () => requestIssues.map((issue) => ({
    id: issue.id.toString(),
    label:
      <>
        <span>{issue.description}</span><br />
        <span>Benefit Type: {BENEFIT_TYPES[issue.benefit_type]}</span><br />
        <span>Decision Date: {formatDateStr(issue.approx_decision_date)}</span>
        <br /><br />
      </>
  }));

  return (
    <>
      <h1>{COPY.REVIEW_SPLIT_APPEAL_CREATE_TITLE}</h1>
      <span>{COPY.REVIEW_SPLIT_APPEAL_CREATE_SUBHEAD}</span>
      <div className="review_appeal_table">
        <table>
          <tr>
            <th></th>
            <th> {COPY.TABLE_ORIGINAL_APPEAL}</th>
            <th> {COPY.TABLE_NEW_APPEAL} </th>
          </tr>
          <tr>
            <td>{COPY.TABLE_VETERANT}</td>
            <td>"Rosalia Turner"</td>
            <td>"Rosalia Turner"</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_DOCKET_NUMBER}</td>
            <td>"191228-283"</td>
            <td>"191228-283"</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_REVIEW_OPTION}</td>
            <td>"Hearing-Video"</td>
            <td>"Hearing-Video"</td>
          </tr>
          <tr>
            <td>{COPY.TABLE_ISSUE}</td>
            <td>
              {requestIssues.map((issue) => {
                return (
                  <ol type ="1">
                    <li>
                      <p>{issue.category}</p>
                      <p>Benefit type: {issue.benefit_type}</p>
                      <p>Decision date: {issue.approx_decision_date}</p>
                    </li>
                  </ol>
                );
              })}
            </td>
          </tr>
        </table>
      </div>
    </>
  );
};

ReviewAppealView.propTypes = {
  serverIntake: PropTypes.object
};
export default ReviewAppealView;
