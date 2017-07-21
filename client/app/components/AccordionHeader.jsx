import React from 'react';
import PropTypes from 'prop-types';

export default class AccordionHeader extends React.PureComponent {

  /* Any props passed in AccordionHeader are rendered in Accordion.jsx
     as child.props */
}

AccordionHeader.propTypes = {
  children: PropTypes.node,
  title: PropTypes.string,
  loading: PropTypes.bool,
  id: PropTypes.string
};
