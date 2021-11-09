import React from 'react';
import PropTypes from 'prop-types';

export const ChevronDown = (props) => {
  const { size, color, cname } = props;

  return <svg height={size} className={cname} viewBox="0 0 14 10" version="1.1" xmlns="http://www.w3.org/2000/svg">
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero" fill={color}>
        <path d="M12.3130435,2.12560386 L6.57777778,7.8531401 C6.47987118,7.9510467 6.36392915,8 6.22995169,8 C6.09597424,8 5.98003221,7.9510467 5.8821256,7.8531401 L0.146859903,2.12560386 C0.0489533011,2.02769726 0,1.91046699 0,1.77391304 C0,1.6373591 0.0489533011,1.52012882 0.146859903,1.42222222 L1.42995169,0.146859903 C1.52785829,0.0489533011 1.64380032,0 1.77777778,0 C1.91175523,0 2.02769726,0.0489533011 2.12560386,0.146859903 L6.22995169,4.25120773 L10.3342995,0.146859903 C10.4322061,0.0489533011 10.5481481,0 10.6821256,0 C10.8161031,0 10.9320451,0.0489533011 11.0299517,0.146859903 L12.3130435,1.42222222 C12.4109501,1.52012882 12.4599034,1.6373591 12.4599034,1.77391304 C12.4599034,1.91046699 12.4109501,2.02769726 12.3130435,2.12560386 Z" id="Shape"></path>
      </g>
    </g>
  </svg>;
};
ChevronDown.propTypes = {

  /**
   * Sets height of the component, width is set automatically by the svg viewbox property. Default height is '10px'.
   */
  size: PropTypes.number,

  /**
     * sets color of the component. Default value is '#0872B9'.
     */
  color: PropTypes.string,

  /**
    * Adds class to the component. Default value is 'table-icon'.
    */
  cname: PropTypes.string
};
ChevronDown.defaultProps = {
  size: 10,
  color: '#0872B9',
  cname: 'table-icon'
};
