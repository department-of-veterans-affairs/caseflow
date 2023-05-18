import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as React from 'react';

import Tooltip from 'app/components/Tooltip';
import { COLORS } from 'app/constants/AppConstants';

const defaultBadgeStyling = {
  display: 'inline-block',
  color: COLORS.WHITE,
  borderRadius: '.5rem',
  lineHeight: '2rem',
  marginLeft: '1rem',
  padding: '0 1rem'
};

/**
 * Component to display a badge. Display name should be all uppercase and no longer than 3 letters
 */
class Badge extends React.PureComponent {
  render = () => {
    const { color, name, displayName, tooltipText, id, ariaLabel } = this.props;

    const badgeStyling = css({
      ...defaultBadgeStyling,
      background: color || COLORS.RED
    });

    return <div className={`cf-${name}-badge`}>
      <Tooltip id={`badge-${id}`} text={tooltipText} position="bottom" ariaLabel={ariaLabel ?? ''}>
        <span {...badgeStyling}>{displayName}</span>
      </Tooltip>
    </div>;
  }
}

Badge.propTypes = {
  color: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  displayName: PropTypes.string.isRequired,
  tooltipText: PropTypes.object,
  id: PropTypes.string,
  ariaLabel: PropTypes.string
};

export default Badge;
