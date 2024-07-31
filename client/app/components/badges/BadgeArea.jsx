import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as React from 'react';

import ContestedClaimBadge from './ContestedBadge/ContestedClaimBadge';
import HearingBadge from './HearingBadge/HearingBadge';
import OvertimeBadge from './OvertimeBadge/OvertimeBadge';
import QueueFnodBadge from './FnodBadge/QueueFnodBadge';
import MstBadge from './MstBadge/MstBadge';
import PactBadge from './PactBadge/PactBadge';
import IntakeBadge from './IntakeBadge/IntakeBadge';
import { mostRecentHeldHearingForAppeal } from 'app/queue/utils';

/**
 * Component to display a set of badges, currently limited to hearing, overtime badges, and FNOD badges.
 * Each badge should individually handle whether or not they should be displayed.
 * This component can accept either an Appeal object or a Task object. An appeal object should be passed in places where
 * we are strictly showing an appeal (in case details or case search). A Task object should be passed in places we do
 * have a task rather than an appeal (in queue task lists). A review obbject should be passed in places we have a
 * ClaimReview rather than an appeal (e.g. case search OtherReviewsTable).
 * The default is for badges to be displayed listed vertically. Pass isHorizontal to display them horizontally
 * e.g.,
 *   <BadgeArea appeal={appeal} />
 *   <BadgeArea task={task} />
 *   <BadgeArea review={review} />
 **
 * These badges were created in the queue application, CASEFLOW-432 adds the FnodBadge to the hearings application
 * To do that the QueueFnodBadge was added, this is a container component which provides the queue state to the
 * FnodBadge component. This allows hearings to use FnodBadge with different feature toggle and tooltip state.
 **/
class BadgeArea extends React.PureComponent {
  render = () => {
    const { appeal, isHorizontal, task, review } = this.props;

    let badges;

    if (appeal) {
      badges = <React.Fragment>
        <ContestedClaimBadge
          appeal={appeal}
          longTooltip={isHorizontal} />
        <QueueFnodBadge appeal={appeal} />
        <HearingBadge hearing={mostRecentHeldHearingForAppeal(appeal)} />
        <OvertimeBadge appeal={appeal} />
        <MstBadge appeal={appeal} />
        <PactBadge appeal={appeal} />
      </React.Fragment>;
    } else if (task) {
      badges = <React.Fragment>
        <ContestedClaimBadge
          appeal={task.appeal}
          longTooltip={isHorizontal} />
        <QueueFnodBadge appeal={task.appeal} />
        <HearingBadge task={task} />
        <OvertimeBadge appeal={task.appeal} />
        <MstBadge appeal={task.appeal} />
        <PactBadge appeal={task.appeal} />
      </React.Fragment>;
    } else {
      // review (ClaimReviews)
      badges = <React.Fragment>
        <IntakeBadge review={review} />
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
  review: PropTypes.object,
  isHorizontal: PropTypes.bool
};

export default BadgeArea;
