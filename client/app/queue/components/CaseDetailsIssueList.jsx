import React from 'react';
import { css } from 'glamor';

import { getIssueDiagnosticCodeLabel } from '../utils';
import ISSUE_INFO from '../../../constants/ISSUE_INFO.json';
import CaseDetailsDescriptionList from './CaseDetailsDescriptionList';
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
  return <React.Fragment>
    {props.issues.map((issue, i) =>
      <div key={i} {...singleIssueContainerStyling}>
        <h3 {...headingStyling}>Issue {1 + i}</h3>
        <IssueDetails>{issue}</IssueDetails>
      </div>
    )}
  </React.Fragment>;
}

const IssueDetails = (props) => {
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
    {/* Following items should only appear for AMA appeals */}
    <IssueDescriptionListItem>{issue.description}</IssueDescriptionListItem>
  </CaseDetailsDescriptionList>;
};

// Encapsulates behaviour to hide row if no value passed in. Maybe this should be renamed?
const DescriptionListItem = (props) => props.children ?
  <React.Fragment><dt>{props.label}</dt><dd {...props.styling}>{props.children}</dd></React.Fragment> :
  null;

const ProgramListItem = (props) => <DescriptionListItem label="Program">
  {props.children ? ISSUE_INFO[props.children].description : null}
</DescriptionListItem>;

const IssueDescriptionsListItem = (props) => {
  if (!props.program || !props.children) {
    return null;
  }

  const codes = props.children.slice();
  let levels = ISSUE_INFO[props.program].levels;

  // Recurse through ISSUE_INFO to get descriptions for the list of codes.
  const descriptions = codes.reduce((elements, code) => {
    if (elements.length) {
      elements.push(<br key={code} />);
    }

    const descr = levels[code].description;

    levels = levels[code].levels;

    return [elements, descr];
  }, []);

  return <DescriptionListItem label="Issue" styling={css({ display: 'table-cell' })}>
    {descriptions}
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

const IssueDescriptionListItem = (props) => <DescriptionListItem label="Description">
  {props.children}
</DescriptionListItem>;
