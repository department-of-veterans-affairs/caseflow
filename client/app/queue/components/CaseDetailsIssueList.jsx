import React from 'react';
import { css } from 'glamor';

import { getIssueDiagnosticCodeLabel } from '../utils';
import ISSUE_DISPOSITIONS_BY_ID from '../../../constants/ISSUE_DISPOSITIONS_BY_ID.json';
import ISSUE_INFO from '../../../constants/ISSUE_INFO.json';
import CaseDetailsDescriptionList from './CaseDetailsDescriptionList';
import ContestedIssues from './ContestedIssues';
import { dispositionLabelForDescription } from './LegacyIssueListItem';

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
  let IssueComponent = LegacyIssueDetails;

  if (!props.isLegacyAppeal && props.amaIssueType) {
    return <ContestedIssues
      requestIssues={props.issues}
    />;
  }

  return <React.Fragment>
    {props.issues.map((issue, i) =>
      <div key={i} {...singleIssueContainerStyling}>
        <h3 {...headingStyling}>Issue {1 + i}</h3>
        { props.isLegacyAppeal ?
          <LegacyIssueDetails>{issue}</LegacyIssueDetails> :
          <AmaIssueDetails>{issue}</AmaIssueDetails>
        }
      </div>
    )}
  </React.Fragment>;
}

const AmaIssueDetails = (props) => <CaseDetailsDescriptionList>
  <dt>Hello! Description</dt><dd>{props.children.description}</dd>
  {props.children.disposition && <React.Fragment>
    <dt>Disposition</dt><dd>{ISSUE_DISPOSITIONS_BY_ID[props.children.disposition]}</dd>
  </React.Fragment>}
</CaseDetailsDescriptionList>;

const LegacyAmaIssueDetails = (props) => <CaseDetailsDescriptionList>
  <dt>Description</dt><dd>{props.children.description}</dd>
  {props.children.disposition && <React.Fragment>
    <dt>Disposition</dt><dd>{ISSUE_DISPOSITIONS_BY_ID[props.children.disposition]}</dd>
  </React.Fragment>}
</CaseDetailsDescriptionList>;

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

const IssueDispositionListItem = (props) => <DescriptionListItem label="Disposition">
  {dispositionLabelForDescription(props.children)}
</DescriptionListItem>;
