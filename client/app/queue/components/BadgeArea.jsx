import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as React from 'react';

import HearingBadge from './HearingBadge';
import { mostRecentHeldHearingForAppeal } from '../utils';

const badgesStyling = css({
  display: 'inline-block'
});

class BadgeArea extends React.PureComponent {
  render = () => {
    const hearing = mostRecentHeldHearingForAppeal(this.props.appeal);

    return <div {...badgesStyling}>
      <HearingBadge hearing={hearing} />
    </div>;
  }
}

BadgeArea.propTypes = {
  appeal: PropTypes.object
};

export default BadgeArea;
