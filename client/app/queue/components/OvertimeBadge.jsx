import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';
import * as React from 'react';
import { connect } from 'react-redux';

import Tooltip from '../../components/Tooltip';
import { COLORS } from '../../constants/AppConstants';

/**
 * This component can accept an appeal
 * e.g.,
 *   <OvertimeBadge appeal={appeal} />
 */

class OvertimeBadge extends React.PureComponent {
  render = () => {
    const { appeal, canViewOvertimeStatus } = this.props;

    if (!appeal.overtime || !canViewOvertimeStatus) {
      return null;
    }

    // TODO: Throw into copy and talk to geronimo
    const tooltipText = <div>
      This case has been approved to be worked in overtime hours
    </div>;

    const badgeStyling = css({
      ...this.props.badgeStyling,
      background: COLORS.GREY_DARK
    });

    return <div className="cf-overtime-badge">
      <Tooltip id={`badge-${appeal.id}`} text={tooltipText} position="bottom">
        <span {...badgeStyling}>OT</span>
      </Tooltip>
    </div>;
  }
}

OvertimeBadge.propTypes = {
  appeal: PropTypes.object,
  badgeStyling: PropTypes.object
};

const mapStateToProps = (state) => ({ canViewOvertimeStatus: state.ui.canViewOvertimeStatus });

export default connect(mapStateToProps)(OvertimeBadge);
