import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as React from 'react';

import HearingBadge from './HearingBadge';
import OvertimeBadge from './OvertimeBadge';
import { mostRecentHeldHearingForAppeal } from '../utils';
import { COLORS } from '../../constants/AppConstants';

const badgeStyling = {
  display: 'inline-block',
  color: COLORS.WHITE,
  borderRadius: '.5rem',
  lineHeight: '2rem',
  marginLeft: '1rem',
  padding: '0 1rem'
};

class BadgeArea extends React.PureComponent {
  render = () => {
    const { appeal, isHorizontal, task } = this.props;
    let badges;

    // TODO: Add helper function to make it clear that this is for case search and case details
    // TODO: Ask geronimo about order and same widths?
    if (appeal) {
      badges = <React.Fragment>
        <HearingBadge hearing={mostRecentHeldHearingForAppeal(appeal)} badgeStyling={badgeStyling}/>
        <OvertimeBadge appeal={appeal} badgeStyling={badgeStyling}/>
      </React.Fragment>;
    } else {
      // TODO: add comment on context (task list)
      badges = <React.Fragment>
        <HearingBadge task={task} badgeStyling={badgeStyling}/>
        <OvertimeBadge appeal={task.appeal} badgeStyling={badgeStyling}/>
      </React.Fragment>
    }

    const badgeAreaStyling = css({
      display: isHorizontal ? 'inline-flex': 'inline-block'
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
