import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as React from 'react';

import HearingBadge from './HearingBadge';

const badgesStyling = css({
  display: 'inline-block'
});

class BadgeArea extends React.PureComponent {
  render = () => {
    return <div {...badgesStyling}>
      <HearingBadge appeal={this.props.appeal} />
    </div>;
  }
}

BadgeArea.propTypes = {
  appeal: PropTypes.object
};

export default BadgeArea;
