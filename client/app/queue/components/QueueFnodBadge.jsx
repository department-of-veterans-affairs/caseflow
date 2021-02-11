import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';

import FnodBadge from './FnodBadge';

// When FnodBadge is used by the Queue app, the relevant state is retrieved from
// the store in this component.
const QueueFnodBadge = ({ fnodBadge, appeal }) => {
  const tooltipText = 'Date of Death Reported';

  return <FnodBadge
    veteranAppellantDeceased={appeal.veteranAppellantDeceased}
    uniqueId={appeal.id}
    show={fnodBadge}
    tooltipText={tooltipText}
  />;
};

QueueFnodBadge.propTypes = {
  appeal: PropTypes.object,
  fnodBadge: PropTypes.bool,
};

// There are places in queue that use this, changing to camelCase seems unwise in this PR
// eslint-disable-next-line
const mapStateToProps = (state) => ({ fnodBadge: state.ui.featureToggles?.fnod_badge });

export default connect(mapStateToProps)(QueueFnodBadge);
