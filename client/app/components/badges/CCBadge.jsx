import PropTypes from 'prop-types';
import * as React from 'react';

import Badge from './Badge';
import { COLORS } from 'app/constants/AppConstants';

/**
 * Component to display if the provided appeal has been approved for overtime work.
 */

const CCBadge = (props) => {
  const { appeal } = props;

  // if () {
  //   return null;
  // }

  const tooltipText = <div>
    This is a Contested Claim and needs to be processed by the Specialty Case team.
    Please include all parties and POA in correspondence.
  </div>;

  return <Badge name="contested" displayName="CC" color={COLORS.PURPLE} tooltipText={tooltipText} />;
};

CCBadge.propTypes = {

};

export default CCBadge;
