import React from 'react';
import PropTypes from 'prop-types';
import Collapse, { Panel } from 'rc-collapse';
import classnames from 'classnames';
import _ from 'lodash';

const CLASS_NAME_MAPPING = {
  bordered: 'usa-accordion-bordered',
  borderless: 'usa-accordion',
  outline: 'usa-accordion-bordered-outline'
};

/*
* The base CSS file for both the Accordion and the AccordionSection components
* originiated from app/assets/stylesheets/react/_rc_collapse.scss. Should there be any styling
* issues for future accordion styles please consult that file along with _main.scss.
*/

export const Accordion = (
  { children, header = null, style, ...passthroughProps }
) => {
  // converting children to an array and mapping through them
  const accordionSections = _.map(
    React.Children.toArray(children),
    (child) => {
      const headerClass = 'usa-accordion-button';
      const headerElement = header || (
        <h3 className="cf-non-stylized-header">
          {child.props.title}
        </h3>
      );
      const {
        children: sectionChildren,
        id: sectionId,
        disabled: sectionIsDisabled,
        title: sectionTitle,
        ...sectionProps
      } = child.props;

      return (
        <Panel id={sectionId}
          disabled={sectionIsDisabled}
          headerClass={
            classnames(headerClass, { disabled: sectionIsDisabled })
          }
          key={`${sectionId}-${sectionTitle}`}
          header={headerElement}
        >
          <div className="usa-accordion-content" {...sectionProps}>
            {sectionChildren}
          </div>
        </Panel>
      );
    }
  );

  /* rc-collapse props:
     accordion: If accordion=true, there can be no more than one active panel at a time.
     defaultActiveKey: shows which accordion headers are expanded on default render
     Source: https://github.com/react-component/collapse */

  return (
    <Collapse {...passthroughProps} className={CLASS_NAME_MAPPING[style]}>
      {accordionSections}
    </Collapse>
  );
};

Accordion.propTypes = {
  accordion: PropTypes.bool,
  children (props, propName, componentName) {
    let error = null;

    React.Children.forEach(props.children, (child) => {
      // It would be more satisfying to compare child.type and AccordionSection directly. However, sometimes
      // this comparison fails. I am not sure why. It will only work if it's the same function instance, so
      // perhaps that gets altered somewhere in React or the importer system. In practice, I think checking
      // the display name will work pretty well. The error message shows only the child type because there
      // might be some unexpected children that are not functions and don't have a type name.
      if (child.type.name !== 'AccordionSection') {
        error = new Error(
          `'${componentName}' children should be of type 'AccordionSection', but was '${child.type}'.`
        );
      }
    });

    return error;
  },
  // Override the default header element.
  // Mutually exclusive with style.
  header: PropTypes.node,
  id: PropTypes.string,
  // Mutually exclusive with header.
  style: PropTypes.string
};
