import React from 'react';
import PropTypes from 'prop-types';
import { ICON_SIZES, COLORS } from '../../constants/AppConstants';

export const ChevronUpIcon = (props) => {
  const { size, color, className } = props;

  return <svg height={size} className={className} viewBox="0 0 17 11" version="1.1" xmlns="http://www.w3.org/2000/svg">
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero" fill={color}>
        <path d="M12.8948156,4.886695 L6.58343916,-1.38094705 C6.35101059,-1.62485579 6.06077157,-1.74675958
        5.71214568,-1.74675958 C5.36351979,-1.74675958 5.07328076,-1.62472091 4.8408522,-1.38094705
        L4.10515053,-0.658764044 C3.86631365,-0.421262414 3.74689521,-0.132571309 3.74689521,0.207612766
        C3.74689521,0.541356005 3.86627974,0.833486719 4.10515053,1.08373514 L8.80976912,5.75327414
        L4.10494709,10.4324238 C3.86617802,10.6699254 3.74675958,10.9586165 3.74675958,11.2988343
        C3.74675958,11.6325439 3.86614412,11.9247757 4.10494709,12.174923 L4.84071657,12.8970048
        C5.07951955,13.1345065 5.37006373,13.2532404 5.71201005,13.2532404 C6.054092,13.2532404
        6.34456837,13.1345065 6.58330353,12.8970048 L12.8948156,6.62936279 C13.1337203,6.37904693
        13.2532404,6.08698365 13.2532404,5.75324042 C13.2532743,5.41305634 13.1337203,5.12419663
        12.8948156,4.886695 Z" id="Shape" transform="translate(8.500000, 5.753240) scale(-1, -1)
        rotate(90.000000) translate(-8.500000, -5.753240) "></path>
      </g>
    </g>
  </svg>;
};
ChevronUpIcon.propTypes = {

  /**
  Sets height of the component, width is set automatically by the svg viewbox property.
  Default height is 'ICON_SIZES.XSMALL'.
  */
  size: PropTypes.number,

  /**
  Sets color of the component. Default value is 'COLORS.PRIMARY'.
  */
  color: PropTypes.string,

  /**
  Adds class to the component. Default value is 'table-icon'.
  */
  className: PropTypes.string
};
ChevronUpIcon.defaultProps = {
  size: ICON_SIZES.XSMALL,
  color: COLORS.PRIMARY,
  className: 'table-icon'
};
