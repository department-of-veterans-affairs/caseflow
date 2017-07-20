import React from 'react';
import PropTypes from 'prop-types';
import Collapse, { Panel } from 'rc-collapse';
import AccordionSection from './AccordionSection';

const CLASS_NAME_MAPPING = {
  bordered: 'usa-accordion-bordered',
  borderless: 'usa-accordion',
  outline: 'usa-accordion-bordered-outline'
};

/*
* The base CSS file for both the Accordion and the AccordionSection components
* originiated from vendor/assets/_rc_collapse.scss. Should there be any styling
* issues for future accordion styles please consult that file along with _main.scss.
*/

export default class Accordion extends React.PureComponent {
  render() {
    const {
      style,
      children,
      ...passthroughProps
    } = this.props;
    
    const accordionSections = children.map((child) => {
      return <Panel header={child.props.title} headerClass="usa-accordion-button"
        key={child.props.title} id={child.props.id}>
          <div className="usa-accordion-content">
            {child.props.children}
          </div>
        </Panel>;
    });

    /* rc-collapse props:
       accordion: If accordion=true, there can be no more than one active panel at a time.
       defaultActiveKey: shows which accordion headers are expanded on default render
       Source: https://github.com/react-component/collapse */

    return <Collapse {...passthroughProps} className={CLASS_NAME_MAPPING[style]}>
      {accordionSections}
    </Collapse>;
  }
}

Accordion.propTypes = {
  accordion: PropTypes.bool,
  children (props, propName, componentName) {
    let error = null;

    React.Children.forEach(props.children, (child) => {
      // It would be more satisfying to compare child.type and AccordionSection directly. However, sometimes
      // this comparison fails. I am not sure why. It will only work if it's the same function instance, so
      // perhaps that gets altered somewhere in React or the importer system. In practice, I think checking
      // the display name will work pretty well.
      if (child.type.displayName !== 'AccordionSection') {
        error = new Error(
          `'${componentName}' children should be of type 'AccordionSection', but was '${child.type.displayName}'.`
        );
      }
    });

    return error;
  },
  id: PropTypes.string,
  style: PropTypes.string.isRequired
};
