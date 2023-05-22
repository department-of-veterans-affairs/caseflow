import React from 'react';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import { getIssueDiagnosticCodeLabel } from '../utils';
import AmaIssueList from '../../components/AmaIssueList';
import ISSUE_INFO from '../../../constants/ISSUE_INFO.json';
import CaseDetailsDescriptionList from './CaseDetailsDescriptionList';
import { dispositionLabelForDescription } from './LegacyIssueListItem';
import DecisionIssues from '../components/DecisionIssues';

const singleIssueContainerStyling = css({
  display: 'inline-block',
  lineHeight: '3rem',
  marginBottom: '3rem',
  paddingRight: '3rem',
  verticalAlign: 'top',
  width: '50%',

  '@media(max-width: 1200px)': { width: '100%' }
});

const headingStyling = css({
  lineHeight: '3rem',
  marginBottom: 0
});

export default function CaseDetailsIssueList(props) {
  if (!props.isLegacyAppeal) {
    return <AmaIssueList
      requestIssues={props.issues}
      decisionIssues={props.decisionIssues}>
      <DecisionIssues
        decisionIssues={props.decisionIssues} />
    </AmaIssueList>;
  }

  return <React.Fragment>
    {props.issues.map((issue, i) =>
      <div key={i} {...singleIssueContainerStyling}>
        <h3 {...headingStyling}>Issue {1 + i}</h3>
        { <LegacyIssueDetails>{issue}</LegacyIssueDetails> }
      </div>
    )}
  </React.Fragment>;
}

const LegacyIssueDetails = (props) => {
  const issue = props.children;
  const codes = issue.codes ? issue.codes.slice() : [];
  const diagnosticCode = getIssueDiagnosticCodeLabel(codes[codes.length - 1]) ? codes.pop() : null;
  const descriptionCodes = [issue.type, ...codes];

  return <CaseDetailsDescriptionList>
    <ProgramListItem>{issue.program}</ProgramListItem>
    <IssueDescriptionsListItem program={issue.program}>{descriptionCodes}</IssueDescriptionsListItem>
    <IssueDiagnosticCodeListItem>{diagnosticCode}</IssueDiagnosticCodeListItem>
    <IssueNoteListItem>{issue.note}</IssueNoteListItem>
    <IssueDispositionListItem>{issue.disposition}</IssueDispositionListItem>
    <IssueNoteListItem>{issue.closed_status}</IssueNoteListItem>
    <SpecialIssueListItem>{issue}</SpecialIssueListItem>
  </CaseDetailsDescriptionList>;
};

// Encapsulates behaviour to hide row if no value passed in. Maybe this should be renamed?
const DescriptionListItem = (props) => props.children ?
  <React.Fragment><dt>{props.label}</dt><dd {...props.styling}>{props.children}</dd></React.Fragment> :
  null;

const ProgramListItem = (props) => <DescriptionListItem label="Program">
  {props.children ? ISSUE_INFO[props.children].description : null}
</DescriptionListItem>;

const getDescriptionsFromCodes = (levels, codes, descriptions = []) => {
  if (codes.length && levels) {
    const code = codes.shift();
    const innerLevel = levels[code];

    if (!innerLevel) {
      return descriptions;
    }

    if (descriptions.length) {
      descriptions.push(<br key={Object.keys(levels).indexOf(code)} />);
    }
    descriptions.push(innerLevel.description);

    return getDescriptionsFromCodes(innerLevel.levels, codes, descriptions);
  }

  return descriptions;
};

// format special issues to display 'None', 'PACT', 'MST', or 'MST and PACT'
const specialIssuesFormatting = (props) => {
  const mstStatus = props.legacy_appeal_vacols_mst;
  const pactStatus = props.legacy_appeal_vacols_pact;

  if (!mstStatus && !pactStatus) {
    return 'None';
  } else if (mstStatus && pactStatus) {
    return 'MST and PACT';
  } else if (mstStatus) {
    return 'MST';
  } else if (pactStatus) {
    return 'PACT';
  }
};

const IssueDescriptionsListItem = (props) => {
  if (!props.program || !props.children) {
    return null;
  }

  return <DescriptionListItem label="Issue" styling={css({ display: 'table-cell' })}>
    {getDescriptionsFromCodes(ISSUE_INFO[props.program].levels, props.children.slice())}
  </DescriptionListItem>;
};

const IssueDiagnosticCodeListItem = (props) => <DescriptionListItem label="Code">
  {getIssueDiagnosticCodeLabel(props.children)}
</DescriptionListItem>;

const IssueNoteListItem = (props) => <DescriptionListItem label="Note" styling={css({ fontStyle: 'italic' })}>
  {props.children}
</DescriptionListItem>;

const SpecialIssueListItem = (props) => <DescriptionListItem label="Special Issues">
  {specialIssuesFormatting(props.children)}
</DescriptionListItem>;

const IssueDispositionListItem = (props) => <DescriptionListItem label="Disposition">
  {dispositionLabelForDescription(props.children)}
</DescriptionListItem>;

CaseDetailsIssueList.propTypes = {
  isLegacyAppeal: PropTypes.bool,
  issues: PropTypes.array,
  title: PropTypes.string,
  decisionIssues: PropTypes.node
};

SpecialIssueListItem.propTypes = {
  children: PropTypes.object,
  legacy_appeal_vacols_mst: PropTypes.bool,
  legacy_appeal_vacols_pact: PropTypes.bool
};
