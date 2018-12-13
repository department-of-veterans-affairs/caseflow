import { css } from 'glamor';
import * as React from 'react';
import ReactTooltip from 'react-tooltip';

import { COLORS } from '../constants/AppConstants';

const Tooltip = (props) => {
  const {
    text,
    id = 'tooltip-id',
    position = 'top',
    offset = {}
  } = props;

  const borderToColor = position.charAt(0).toUpperCase() + position.slice(1);
  const tooltipStyling = css({
    display: 'inline-block',
    [`& #${id}`]: {
      backgroundColor: COLORS.GREY_DARK,
      fontWeight: 'normal',
      padding: '0.5rem 1rem',
      textAlign: 'center'
    },
    [`& #${id}:after`]: { [`border${borderToColor}Color`]: COLORS.GREY_DARK }
  });

  const iconStyling = css({
    paddingLeft: '0.5rem'
  });

  return <React.Fragment>
    <span {...iconStyling} data-tip data-for={id}>{props.children}</span>
    <span {...tooltipStyling} >
      <ReactTooltip effect="solid" id={id} offset={offset} place={position} multiline>{text}</ReactTooltip>
    </span>
  </React.Fragment>;
};

export default Tooltip;
