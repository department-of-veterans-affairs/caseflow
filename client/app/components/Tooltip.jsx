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
    offset = {},
    tabIndex = 0,
    styling = 'inline-block',
    className = 'cf-tooltip',
    ariaLabel
  } = props;

  const borderToColor = position.charAt(0).toUpperCase() + position.slice(1);
  const tooltipStyling = css({
    display: styling,
    [`& #${id}`]: {
      backgroundColor: COLORS.GREY_DARK,
      fontWeight: 'normal',
      padding: '0.5rem 1rem',
      textAlign: 'justify'
    },
    [`& #${id}:after`]: { [`border${borderToColor}Color`]: COLORS.GREY_DARK }
  });

  // These props are applied to the children in order to establish link to tooltip
  const tooltipProps = {
    'aria-describedby': id,
    'data-tip': true,
    'data-for': id,
    'data-event': 'focus mouseenter',
    'data-event-off': 'mouseleave keydown',
    tabIndex,
    'aria-label': ariaLabel ?? ''
  };

  return (
    <React.Fragment>
      {React.cloneElement(props.children, tooltipProps)}
      <span {...tooltipStyling}>
        <ReactTooltip
          effect="solid"
          id={id}
          offset={offset}
          place={position}
          multiline
          role="tooltip"
          className={className}
        >
          {text}
        </ReactTooltip>
      </span>
    </React.Fragment>
  );
};

Tooltip.propTypes = {
  text: PropTypes.any,
  id: PropTypes.string,
  position: PropTypes.string,
  offset: PropTypes.object,
  children: PropTypes.object,
  tabIndex: PropTypes.number,
  styling: PropTypes.string,
  className: PropTypes.string,
  ariaLabel: PropTypes.string
};

export default Tooltip;
