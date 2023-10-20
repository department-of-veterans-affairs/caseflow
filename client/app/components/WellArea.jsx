import React from 'react';
import PropTypes from 'prop-types';

const WellArea = (props) => {
  return (<div style={{
    display: 'flex',
    border: '1px solid black',
    width: '100%'
  }}>
    {props.children}
  </div>);
};

export default WellArea;

WellArea.propTypes = {
  children: PropTypes.node,
};
