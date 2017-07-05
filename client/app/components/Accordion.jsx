import React from 'react';
import PropTypes from 'prop-types';
import Collapse, { Panel } from 'rc-collapse';
import AccordionHeader from './AccordionHeader';

const CLASS_NAME_MAPPING = {
  bordered: 'usa-accordion-bordered',
  borderless: 'usa-accordion',
  outline: 'usa-accordion-bordered-outline'
};

/*
* The base CSS file for both the Accordion and the AccordionHeader components
* originiated from vendor/assets/_rc_collapse.scss. Should there be any styling
* issues for future accordion styles please consult that file along with _main.scss.
*/

export default class Accordion extends React.PureComponent {
  render() {
    const {
      accordion,
      children,
      defaultActiveKey,
      style
    } = this.props;

    const accordionHeaders = children.map((child) => {
      if (child.type === AccordionHeader) {
        return <Panel header={child.props.title} headerClass="usa-accordion-button" key={child.props.title}>
          <div className="usa-accordion-content">
            {child.props.children}
          </div>
        </Panel>;
      }
    });

    /* If accordion=true, there can be no more than one active panel at a time.
    Source: https://github.com/react-component/collapse */

    return <Collapse accordion={accordion} className={CLASS_NAME_MAPPING[style]}
      defaultActiveKey={defaultActiveKey}>
      {accordionHeaders}
    </Collapse>;
  }
}

Accordion.propTypes = {
  accordion: PropTypes.bool,
  children: PropTypes.node,
  style: PropTypes.string.isRequired
};
