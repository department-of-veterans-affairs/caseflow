import React from 'react';
import PropTypes from 'prop-types';

// Not used anywhere

export const MissingSymbol = (props) => {
  const { color, size, cname } = props;

  return (
    <svg height={size} className={cname}
      xmlns="http://www.w3.org/2000/svg" viewBox="0 0 55 55">
      <title>missing icon</title>
      <g fill={color}>
        <path d="M52.6 46.9l-6 6c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-13-13-13
        13c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-6-6c-.8-.8-1.2-1.9-1.2-3s.4-2.2
        1.2-3l13-13-13-13c-.8-.8-1.2-1.9-1.2-3s.4-2.2 1.2-3l6-6c.8-.8 1.9-1.2
        3-1.2s2.2.4 3 1.2l13 13 13-13c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l6 6c.8.8
        1.2 1.9 1.2 3s-.4 2.2-1.2 3l-13 13 13 13c.8.8 1.2 1.9 1.2 3s-.4 2.2-1.2 3z" />
      </g>
    </svg>
  );
};
MissingSymbol.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property. Default height is '55px'.
  */
  size: PropTypes.string,

  /**
  Sets the color of the component. Default color is red.
  */
  color: PropTypes.string,

  /**
  Sets the className of the component. Default class is empty.
  */
  cname: PropTypes.string,
};
MissingSymbol.defaultProps = {
  size: '55',
  color: '',
  cname: 'cf-icon-missing'
};
