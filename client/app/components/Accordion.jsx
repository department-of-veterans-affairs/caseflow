import React from 'react';
import PropTypes from 'prop-types';
import Collapse, { Panel } from 'rc-collapse';

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
      children,
      style
    } = this.props;
    const accordionHeaders = React.Children.map(children, (child) => {
      let headerClass = "usa-accordion-button";

      return <Panel id={child.props.id} showArrow={false} 
        headerClass={child.props.loading ? `${headerClass} loading` : headerClass}
        header={child.props.title} key={child.props.title}>
        <div className="usa-accordion-content">
          {child.props.children}
        </div>
      </Panel>;
    });

    return <Collapse className={CLASS_NAME_MAPPING[style]}>
      {accordionHeaders}
    </Collapse>;
  }
}

Accordion.propTypes = {
  children: PropTypes.node,
  style: PropTypes.string.isRequired
};
