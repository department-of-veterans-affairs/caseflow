import PropTypes from 'prop-types';
import _ from 'lodash';
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { COLORS } from '../../constants/AppConstants';
import { tooltipListStyling } from './style';

import Badge from './Badge';
import ApiUtil from '../../util/ApiUtil';
import { DateString } from '../../util/DateUtil';
import { setMostRecentlyHeldHearingForAppeal } from '../QueueActions';

/**
 * Component to display hearing information associated with a hearing. If a task is provided to the badge, a request is
 * sent to the back end to pull hearing information if there is a hearing associated with the task's appeal.
 * This component can accept either a Hearing object or a Task object.
 * e.g.,
 *   <HearingBadge hearing={hearing} />
 *   <HearingBadge task={task} />
 */

class HearingBadge extends React.PureComponent {
  componentDidMount = () => {
    if (!this.props.mostRecentlyHeldHearingForAppeal && !this.props.hearing && this.props.externalId) {
      ApiUtil.get(`/appeals/${this.props.externalId}/hearings`).then((response) => {
        this.props.setMostRecentlyHeldHearingForAppeal(this.props.externalId, response.body);
      }).
        catch((err) => {
          // we don't care if the browser gave up for some reason.
          if (err.message.match(/Request has been terminated|Response timeout/)) {
            return;
          }

          const error = new Error(`There was an error getting hearings for appeal ${this.props.externalId} ${err}`);

          if (window.Raven) {
            window.Raven.captureException(error);
          }
          console.error(error);
        });
    }
  }

  render = () => {
    const hearing = this.props.mostRecentlyHeldHearingForAppeal || this.props.hearing;

    if (!hearing || !hearing.date) {
      return null;
    }

    const tooltipText = <div>
      This case has a hearing associated with it.
      <ul {...tooltipListStyling}>
        <li>Judge: <strong>{hearing.heldBy}</strong></li>
        <li>Disposition: <strong>{_.startCase(hearing.disposition)}</strong></li>
        <li>Date: <strong><DateString date={hearing.date} /></strong></li>
        <li>Type: <strong>{_.startCase(hearing.type)}</strong></li>
      </ul>
    </div>;

    return <Badge name="hearing" displayName="H" color={COLORS.GREEN} tooltipText={tooltipText} id={hearing.id} />;
  }
}

HearingBadge.propTypes = {
  externalId: PropTypes.string,
  hearing: PropTypes.object,
  mostRecentlyHeldHearingForAppeal: PropTypes.object,
  setMostRecentlyHeldHearingForAppeal: PropTypes.func,
  task: PropTypes.object
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
    mostRecentlyHeldHearingForAppeal: state.queue.mostRecentlyHeldHearingForAppeal[externalId] || null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setMostRecentlyHeldHearingForAppeal
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(HearingBadge);
