import * as React from 'react';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import Button from '../../components/Button';
import ISSUE_DISPOSITIONS_BY_ID from '../../../constants/ISSUE_DISPOSITIONS_BY_ID.json';

const TEXT_INDENTATION = '10px'; 

const contestedIssueStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  padding: `5px ${TEXT_INDENTATION}`,
  margin: '10px 0'
});

const indentedIssueStyling = css({
  margin: `0 ${TEXT_INDENTATION}`
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

const descriptionSpan = css({
  marginRight: '10px'
});

const grayLine = css({
  width: '4px',
  minHeight: '20px',
  background: COLORS.GREY_LIGHT,
  marginLeft: '20px',
  marginBottom: '10px'
});

const flexContainer = css({
  display: 'flex',
  justifyContent: 'space-between'
});

const noteDiv = css({
  marginTop: '10px',
  fontSize: '1.5rem',
  color: COLORS.GREY
});

export default class ContestedIssues extends React.PureComponent {
  decisionIssues = (requestIssue) => {
    const {
      decisionIssues,
      openDecisionHandler
    } = this.props;

    return decisionIssues.filter((decisionIssue) => {
      return decisionIssue.request_issue_ids.includes(requestIssue.id);
    }).map((decisionIssue) => {
      return <div {...outerDiv}>
        <div {...grayLine}/>
        <div {...decisionIssueDiv}>
          <div {...flexContainer}>
            Decision
            {openDecisionHandler && <span>
              <Button
                name="Edit"
                onClick={openDecisionHandler([requestIssue.id], decisionIssue)}
                classNames={['cf-btn-link']}
              />
            </span>}
          </div>
          <div {...descriptionDiv} {...flexContainer}>
            <span {...descriptionSpan}>
              {decisionIssue.description}
            </span>
            <span>
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
      openDecisionHandler,
      numbered
    } = this.props;

    const listStyle = css({
      listStyleType: numbered ? 'decimal' : 'none',
      paddingLeft: numbered ? 'inherit' : '0'
    });

    const listPadding = css({
      paddingLeft: numbered ? '5px' : '0'
    });

    return <ol {...listStyle}>{requestIssues.map((issue) => {
        return <li {...listPadding} key={issue.description}>
          <div {...contestedIssueStyling}>
            Contested Issue
          </div>
          <div {...indentedIssueStyling}>
            {issue.description}
            <div {...noteDiv}>Note: "{issue.notes}"</div>
          </div>
          {this.decisionIssues(issue)}
          { openDecisionHandler &&
            <div {...buttonDiv}>
              <Button
                name="+ Add Decision"
                onClick={openDecisionHandler([issue.id])}
                classNames={['usa-button-secondary']}
              />
            </div>
          }
        </li>;
      })}
    </ol>;
  }
}
