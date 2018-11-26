import * as React from 'react';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import Button from '../../components/Button';
import ISSUE_DISPOSITIONS_BY_ID from '../../../constants/ISSUE_DISPOSITIONS_BY_ID.json';

const contestedIssueStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  padding: '0 20px',
  margin: '10px 0'
});

const indentedIssueStyling = css({
  margin: '0 10px'
});

const buttonDiv = css({
  textAlign: 'right',
  margin: '20px 0'
});

const outerDiv = css({
  marginLeft: '50px',
  marginTop: '10px'
});

const decisionIssueDiv = css({
  border: `2px solid ${COLORS.GREY_LIGHT}`,
  borderRadius: '5px',
  padding: '10px'
});

const descriptionDiv = css({
  marginTop: '10px'
});

const dispositionSpan = css({
  float: 'right'
});

const grayLine = css({
  width: '4px',
  minHeight: '20px',
  background: COLORS.GREY_LIGHT,
  marginLeft: '20px',
  marginBottom: '10px'
});

export default class ContestedIssues extends React.PureComponent {
  decisionIssues = (requestIssue) => {
    const {
      decisionIssues,
      editDecisionHandler
    } = this.props;

    return decisionIssues.filter((decisionIssue) => {
      return requestIssue.decision_issue_ids.includes(decisionIssue.id);
    }).map((decisionIssue) => {
      return <div {...outerDiv}>
        <div {...grayLine}/>
        <div {...decisionIssueDiv}>
          <div>
            Decision
            {editDecisionHandler && <span {...dispositionSpan}>
              <Button
                name="Edit"
                onClick={editDecisionHandler([decisionIssue.id])}
                classNames={['cf-btn-link']}
              />
            </span>}
          </div>
          <div {...descriptionDiv}>
            <span>
              {decisionIssue.description}
            </span>
            <span {...dispositionSpan}>
              {ISSUE_DISPOSITIONS_BY_ID[decisionIssue.disposition]}
            </span>
          </div>
        </div>
      </div>;
    });
  }

  render = () => {
    const {
      requestIssues,
      decisionIssues,
      addDecisionHandler
    } = this.props;

    return requestIssues.map((issue) => {
      return <React.Fragment key={issue.description}>
        <div {...contestedIssueStyling}>
          Contested Issue
        </div>
        <div {...indentedIssueStyling}>
          {issue.description}
          <div>Note: "{issue.notes}"</div>
        </div>
        {this.decisionIssues(issue)}
        { addDecisionHandler &&
          <div {...buttonDiv}>
            <Button
              name="+ Add Decision"
              onClick={addDecisionHandler([issue.id])}
              classNames={['usa-button-secondary']}
            />
          </div>
        }
      </React.Fragment>;
    });
  }
}
