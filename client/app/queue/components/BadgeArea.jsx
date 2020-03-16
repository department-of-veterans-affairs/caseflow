import PropTypes from 'prop-types';
import * as React from 'react';

import HearingBadge from './HearingBadge';

class BadgeArea extends React.PureComponent {
  render = () => {
    return <div>
      <HearingBadge appeal={this.props.appeal} />
    </div>;
  }
}

BadgeArea.propTypes = {
  appeal: PropTypes.object
};

export default HearingBadge;
