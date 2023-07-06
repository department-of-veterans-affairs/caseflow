import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from '../Badge';
import { COLORS } from 'app/constants/AppConstants';
import { connect } from 'react-redux';

/**
 * Component to display if the appeal is a mst.
 */

const MstBadge = (props) => {
  const { appeal, appealDetails } = props;

  if (appealDetails[appeal.externalId]?.issues) {
    const issues = appealDetails[appeal.externalId].issues;

    if (!issues.some((issue) => issue.mst_status === true)) {
      return null;
    }
  } else if (!appeal?.mst) {
    return null;
  }

  const tooltipText = 'Appeal has issue(s) related to Military Sexual Trauma';

  return <Badge
    name="mst"
    displayName="MST"
    color={COLORS.GRAY}
    tooltipText={tooltipText}
    id={`mst-${appeal.id}`}
    ariaLabel="mst"
  />;
};

MstBadge.propTypes = {
  appeal: PropTypes.object,
  appealDetails: PropTypes.object
};

const mapStateToProps = (state) => ({
  appealDetails: state.queue.appealDetails,
});

export default connect(
  mapStateToProps
)(MstBadge);
