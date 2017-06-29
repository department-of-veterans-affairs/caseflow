import React from 'react';
import PropTypes from 'prop-types';
import { AccordionItem } from 'react-sanfona';

export default class AccordionHeader extends React.Component {
  render() {
    const {
      accordionKey,
      title,
      children
    } = this.props;

    return <AccordionItem title={title} key={accordionKey}>
      {children}
    </AccordionItem>
  }
}

AccordionHeader.propTypes = {
  children: PropTypes.node,
  key: PropTypes.node,
  title: PropTypes.string
};
