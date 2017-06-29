import React from 'react';
import PropTypes from 'prop-types';
import Collapse, { Panel } from 'rc-collapse';

const CLASS_NAME_MAPPING = {
  bordered: 'usa-accordion-bordered',
  borderless: 'usa-accordion',
  outline: 'usa-accordion-bordered-outline'
};

export default class Accordion extends React.PureComponent {
  render() {
    const {
      children,
      style
    } = this.props;

    const accordionHeaders = children.map((child) => {
      return <Panel header={child.props.title} headerClass="usa-accordion-button" key={child.props.title}>
        <div className="usa-accordion-content">
          {child.props.children}
        </div>
      </Panel>;
    });

    return <Collapse accordion={true} className={CLASS_NAME_MAPPING[style]}>
      {accordionHeaders}
    </Collapse>;
  }
}

Accordion.propTypes = {
  children: PropTypes.node,
  style: PropTypes.string.isRequired
};
