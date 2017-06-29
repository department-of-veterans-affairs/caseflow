import React from 'react';
import PropTypes from 'prop-types';
import { Accordion } from 'react-sanfona';
import AccordionHeader from './AccordionHeader';

const CLASS_NAME_MAPPING = {
  bordered: 'usa-accordion-bordered',
  borderless: 'usa-accordion',
  outline: 'usa-accordion-bordered-outline'
};

export default class AccordionGroup extends React.Component {
  render() {
    const {
      children,
      style
    } = this.props;

    return <Accordion className={CLASS_NAME_MAPPING[style]}>
      {children}
    </Accordion>
  }
}

AccordionGroup.propTypes = {
  children: PropTypes.node,
  style: PropTypes.string.isRequired
};
