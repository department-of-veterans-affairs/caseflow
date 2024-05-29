import React from 'react';
import PropTypes from 'prop-types';
import issueSectionRow from './issueSectionRow';
import Table from 'app/components/Table';
import { issueSectionRowProps } from './mockData';

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

BaseComponent.propTypes = {
  content: PropTypes.element,
  field: PropTypes.string
};
