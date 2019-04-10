import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';
import * as React from 'react';
import { connect } from 'react-redux';

import Tooltip from '../../components/Tooltip';
import { COLORS } from '../../constants/AppConstants';

import { DateString } from '../../util/DateUtil';

/**
 * This component can accept either a Hearing object or a Task object.
 * e.g.,
 *   <HearingBadge hearing={hearing} />
 *   <HearingBadge task={task} />
 */

const badgeStyling = css({
  display: 'inline-block',
  color: COLORS.WHITE,
  background: COLORS.GREEN,
  borderRadius: '.5rem',
  lineHeight: '2rem',
  marginLeft: '1rem',
  padding: '0 1rem'
});

const listStyling = css({
  listStyle: 'none',
  textAlign: 'left',
  marginBottom: 0,
  padding: 0,
  '& > li': {
    marginBottom: 0,
    '& > strong': {
      color: COLORS.WHITE
    }
  }
});

class HearingBadge extends React.PureComponent {

  render = () => {
    const { externalId, mostRecentlyHeldHearingsById } = this.props;
    const hearing =
    mostRecentlyHeldHearingsById.filter((hearingObj) => hearingObj.appealId === externalId)[0] ||
    this.props.hearing;

    if (!hearing || !hearing.date) {
      return null;
    }

    const tooltipText = <div>
      This case has a hearing associated with it.
      <ul {...listStyling}>
        <li>Judge: <strong>{hearing.heldBy}</strong></li>
        <li>Disposition: <strong>{_.startCase(hearing.disposition)}</strong></li>
        <li>Date: <strong><DateString date={hearing.date} /></strong></li>
        <li>Type: <strong>{_.startCase(hearing.type)}</strong></li>
      </ul>
    </div>;

    return <div {...css({ marginRight: '-2.5rem' })} className="cf-hearing-badge">
      <Tooltip id={`badge-${hearing.id}`} text={tooltipText} position="bottom">
        <span {...badgeStyling}>H</span>
      </Tooltip>
    </div>;
  }
}

HearingBadge.propTypes = {
  task: PropTypes.object,
  hearing: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  let externalId, hearing;

  if (ownProps.hearing) {
    hearing = ownProps.hearing;
  } else if (ownProps.task) {
    externalId = ownProps.task.appeal.externalId;
  }

  return {
    hearing,
    externalId,
    mostRecentlyHeldHearingsById: state.queue.mostRecentlyHeldHearingsById
  };
};

export default connect(mapStateToProps)(HearingBadge);
