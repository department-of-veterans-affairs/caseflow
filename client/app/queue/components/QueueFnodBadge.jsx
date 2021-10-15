import PropTypes from 'prop-types';
import * as React from 'react';
import { DateString } from '../../util/DateUtil';
import { tooltipListStyling } from './style';
import { connect } from 'react-redux';
import COPY from '../../../COPY';

import FnodBadge from './FnodBadge';

// When FnodBadge is used by the Queue app, the relevant state is retrieved from
// the store in this component.
const QueueFnodBadge = ({ fnodBadge, appeal }) => {
  const tooltipText = <div>
    <strong>Date of Death Reported</strong>
    <ul {...tooltipListStyling}>
      <li><strong>Source:</strong> {COPY.FNOD_SOURCE}</li>
      { appeal.veteranDateOfDeath &&
        <li><strong>Date of Death:</strong> <DateString date={appeal.veteranDateOfDeath} /></li>
      }
    </ul>
  </div>;

  return <div>
    {fnodBadge &&
      <FnodBadge
        veteranAppellantDeceased={appeal.veteranAppellantDeceased}
        uniqueId={appeal.id}
        tooltipText={tooltipText}
      />}
  </div>;
};

QueueFnodBadge.propTypes = {
  appeal: PropTypes.object,
  fnodBadge: PropTypes.bool,
};

// There are places in queue that use this, changing to camelCase seems unwise in this PR
// eslint-disable-next-line
const mapStateToProps = (state) => ({ fnodBadge: state.ui.featureToggles?.fnod_badge });

export default connect(mapStateToProps)(QueueFnodBadge);
