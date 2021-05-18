import { css } from 'glamor';
import * as React from 'react';
import ReactTooltip from 'react-tooltip';
import PropTypes from 'prop-types';

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

  return <React.Fragment>
    <span data-tip data-for={id} role="tooltip" data-event="focus mouseenter"
      data-event-off="keydown mouseleave" tabIndex={-1} aria-describedby={id}>{props.children}</span>
    <span {...tooltipStyling} >
      <ReactTooltip effect="solid" id={id} offset={offset} place={position} multiline>{text}</ReactTooltip>
    </span>
  </React.Fragment>;
};

Tooltip.propTypes = {
  text: PropTypes.string,
  id: PropTypes.string,
  position: PropTypes.string,
  offset: PropTypes.object,
  children: PropTypes.object
};

export default Tooltip;
