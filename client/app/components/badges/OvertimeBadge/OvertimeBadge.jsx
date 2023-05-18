import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if the provided appeal has been approved for overtime work.
 */

class OvertimeBadge extends React.PureComponent {
  render = () => {
    const { appeal, canViewOvertimeStatus } = this.props;

    if (!appeal.overtime || !canViewOvertimeStatus) {
      return null;
    }

    const tooltipText = <div>
      This case has been approved to be worked in overtime hours
    </div>;

    return <Badge name="overtime" displayName="OT" color={COLORS.GREY_DARK} tooltipText={tooltipText} id={appeal.id}
      ariaLabel="overtime" />;
  }
}

OvertimeBadge.propTypes = {
  appeal: PropTypes.object,
  canViewOvertimeStatus: PropTypes.bool
};

const mapStateToProps = (state) => ({ canViewOvertimeStatus: state.ui.canViewOvertimeStatus });

export default connect(mapStateToProps)(OvertimeBadge);
