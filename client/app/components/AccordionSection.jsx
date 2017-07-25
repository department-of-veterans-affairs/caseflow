import React from 'react';
import PropTypes from 'prop-types';

export default class AccordionSection extends React.PureComponent {

  /* Any props passed in AccordionSection are rendered in Accordion.jsx
     as child.props */
}

AccordionSection.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string,
  disabled: PropTypes.bool,
  id: PropTypes.string
};
