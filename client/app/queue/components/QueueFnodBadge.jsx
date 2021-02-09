import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';

import FnodBadge from './FnodBadge';

// When FnodBadge is used by the Queue app, the relevant state is retrieved from
// the store in this component.
const QueueFnodBadge = (props) => {
  const tooltipText = 'Date of Death Reported';

  return <FnodBadge appeal={props.appeal} show={props.fnod_badge} tooltipText={tooltipText} />;
};

QueueFnodBadge.propTypes = {
  appeal: PropTypes.object,
  fnod_badge: PropTypes.bool,
};

const mapStateToProps = (state) => ({ fnod_badge: state.ui.featureToggles?.fnod_badge });

export default connect(mapStateToProps)(QueueFnodBadge);
