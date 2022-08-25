import React, { useContext } from 'react';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import { css } from 'glamor';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import CheckboxGroup from '../../components/CheckboxGroup';
import SPLIT_APPEAL_REASONS from '../../../constants/SPLIT_APPEAL_REASONS';
import { formatDateStr } from '../../util/DateUtil';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import _ from 'lodash';

const issueListStyling = css({ marginTop: '0rem', marginLeft: '6rem' });

const ReviewAppealView = (props) => {
  const { serverIntake } = props;
  const {
    reason,
    setReason,
    otherReason,
    setOtherReason,
    selectedIssues,
    setSelectedIssues
  } = useContext(StateContext);
  const requestIssues = serverIntake.requestIssues;

  const onReasonChange = (selection) => {
    setReason(selection.value);
  };

  const reasonOptions = _.map(SPLIT_APPEAL_REASONS, (value) => ({
    label: value,
    value
  }));

  const onOtherReasonChange = (value) => {
    setOtherReason(value);
  };

  const onIssueChange = (evt) => {
    setSelectedIssues({ ...selectedIssues, [evt.target.name]: evt.target.checked });
  };

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
      <>
        <h1>{COPY.SPLIT_APPEAL_CREATE_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_CREATE_SUBHEAD}</span>
        <br /><br />
        <SearchableDropdown
          name="splitAppealReasonDropdown"
          label={COPY.SPLIT_APPEAL_CREATE_REASONING_TITLE}
          strongLabel
          value={reason}
          onChange={onReasonChange}
          options={reasonOptions}
        />
        <br />
        {reason === 'Other' && (
          <TextareaField
            name="reason"
            label="Reason for split"
            id="otherReason"
            textAreaStyling={css({ height: '50px' })}
            maxlength={350}
            value={otherReason}
            onChange={onOtherReasonChange}
            optional
          />
        )}
        <br />
        <h3>{COPY.SPLIT_APPEAL_CREATE_SELECT_ISSUES_TITLE}</h3>
        <CheckboxGroup
          vertical
          name="issues"
          label={COPY.SPLIT_APPEAL_CREATE_SELECT_ISSUES_TITLE}
          hideLabel
          values={selectedIssues}
          onChange={(val) => onIssueChange(val)}
          options={issueOptions()}
          styling={issueListStyling}
          strongLabel
        />
      </>
      <div>
        <h1 style={{ margin: '0px' }}>{COPY.SPLIT_APPEAL_REVIEW_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_REVIEW_SUBHEAD}</span>
      </div> &ensp;
      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'left' }}>
        <u>{COPY.SPLIT_APPEAL_REVIEW_REASONING_TITLE}</u> &ensp;
        <span style={{ flexBasis: '75%' }}>{reason}</span>
      </div>
      <div className="review_appeal_table">
        <table>
          <tr>
            <th></th>
            <th> {COPY.TABLE_ORIGINAL_APPEAL}</th>
            <th> {COPY.TABLE_NEW_APPEAL} </th>
          </tr>
          <tr>
            <td>{COPY.TABLE_VETERAN}</td>
            <td>{requestIssues.map((issue) => {
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
