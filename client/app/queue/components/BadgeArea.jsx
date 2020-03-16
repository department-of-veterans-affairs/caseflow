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
    return <div {...badgesStyling}>
      {this.props.appeal ?
        <HearingBadge hearing={mostRecentHeldHearingForAppeal(this.props.appeal)} /> :
        <HearingBadge task={this.props.task} />}
    </div>;
  }
}

BadgeArea.propTypes = {
  appeal: PropTypes.object,
  task: PropTypes.object
};

export default BadgeArea;
