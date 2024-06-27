import React from 'react';
import PropTypes from 'prop-types';
import issueSectionRow from './issueSectionRow';
import Table from 'app/components/Table';
import { issueSectionRowProps, issueSectionRowDataProps, issueSectionRowDataNonAdminProps } from './mockData';

export default {
  title: 'Intake/Edit Issues/Issue Section Row',
  decorators: [],
  parameters: {},
};

const BaseComponent = ({ content, field }) => (
  <div className="cf-intake-edit">
    <Table columns={[{ valueName: 'field' }, { valueName: 'content' }]} rowObjects={[{ field, content }]} />
  </div>
);

export const Basic = () => {
  const Component = issueSectionRow({
    ...issueSectionRowProps,
    fieldTitle: 'Withdrawn issues',
  });

  return (
    <BaseComponent content={Component.content} field={Component.field} />
  );
};

export const WithNoDecisionDate = () => {
  issueSectionRowProps.sectionIssues[0].date = null;

  const Component = issueSectionRow({
    ...issueSectionRowProps,
    fieldTitle: 'Withdrawn issues',
  });

  return (
    <BaseComponent content={Component.content} field={Component.field} />
  );
};

const RequestIssuesTemplate = (args) => {
  const Component = issueSectionRow({
    ...args,
    fieldTitle: 'Requested issues',
  });

  return (
    <BaseComponent content={Component.content} field={Component.field} />
  );
};

export const withoutPendingRequestIssuesForAdmin = RequestIssuesTemplate.bind({});
withoutPendingRequestIssuesForAdmin.args = issueSectionRowProps;

export const withPendingRequestIssuesForAdmin = RequestIssuesTemplate.bind({});
withPendingRequestIssuesForAdmin.args = issueSectionRowDataProps;

export const requestIssuesForNonAdmin = RequestIssuesTemplate.bind({});
requestIssuesForNonAdmin.args = issueSectionRowDataNonAdminProps;

BaseComponent.propTypes = {
  content: PropTypes.element,
  field: PropTypes.string
};
