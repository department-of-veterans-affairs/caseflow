import React from 'react';
import PropTypes from 'prop-types';
import Collapse, { Panel } from 'rc-collapse';
import AccordionHeader from './AccordionHeader';
import classnames from 'classnames';

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
      classNames,
      defaultActiveKey,
      id,
      style
    } = this.props;

    const accordionHeaders = children.map((child) => {
      return <Panel header={child.props.title} headerClass="usa-accordion-button" key={child.props.title} id={child.props.id}>
          <div className="usa-accordion-content">
            {child.props.children}
          </div>
        </Panel>;
    });

    const accordionStyle = classnames({
      'usa-accordion-bordered': style === 'bordered',
      'usa-accordion': style === 'borderless',
      'usa-accordion-bordered-outline': style === 'outline'
    });

    /* rc-collapse props:
       accordion: If accordion=true, there can be no more than one active panel at a time.
       defaultActiveKey: shows which accordion headers are expanded on default render
       Source: https://github.com/react-component/collapse */

    return <Collapse accordion={accordion} className={classnames(classNames, accordionStyle)}
      defaultActiveKey={defaultActiveKey} id={id}>
      {accordionHeaders}
    </Collapse>;
  }
}

Accordion.propTypes = {
  accordion: PropTypes.bool,
  children (props, propName, componentName) {
    const prop = props[propName];

    let error = null;

    React.Children.forEach(prop, (child) => {
      if (child.type !== AccordionHeader) {
        error = new Error(`\`${componentName}\` children should be of type \`AccordionHeader\`.`);
      }
    });

    return error;
  },
  id: PropTypes.string,
  style: PropTypes.string.isRequired
};
