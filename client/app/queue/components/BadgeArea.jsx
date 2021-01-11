import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as React from 'react';

import FnodBadge from './FnodBadge';
import HearingBadge from './HearingBadge';
import OvertimeBadge from './OvertimeBadge';
import { mostRecentHeldHearingForAppeal } from '../utils';

/**
 * Component to display a set of badges, currently limited to hearing, overtime badges, and FNOD badges.
 * Each badge should individually handle whether or not they should be displayed.
 * This component can accept either an Appeal object or a Task object. An appeal object should be passed in places where
 * we are strictly showing an appeal (in case details or case search). A Task object should be passed in places we do
 * have a task rather than an appeal (in queue task lists)
 * The default is for badges to be displayed listed vertically. Pass isHorizontal to display them horizontally
 * e.g.,
 *   <BadgeArea appeal={appeal} />
 *   <BadgeArea task={task} />
 */
class BadgeArea extends React.PureComponent {
  render = () => {
    const { appeal, isHorizontal, task } = this.props;

    let badges;

    if (appeal) {
      badges = <React.Fragment>
        <FnodBadge appeal={appeal} />
        <HearingBadge hearing={mostRecentHeldHearingForAppeal(appeal)} />
        <OvertimeBadge appeal={appeal} />
      </React.Fragment>;
    } else {
      badges = <React.Fragment>
        <FnodBadge appeal={task.appeal} />
        <HearingBadge task={task} />
        <OvertimeBadge appeal={task.appeal} />
      </React.Fragment>;
    }

    const badgeAreaStyling = css({
      display: isHorizontal ? 'inline-flex' : 'inline-block'
    });

    return <div {...badgeAreaStyling}>{badges}</div>;
  }
}

BadgeArea.propTypes = {
  appeal: PropTypes.object,
  task: PropTypes.object,
  isHorizontal: PropTypes.bool
};

export default BadgeArea;
