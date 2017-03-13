import React, { PropTypes } from 'react';

/**
 * This component is to be used with the ProgressBar component.
 */
export default class ProgressBarSection extends React.Component {
  render() {
    let {
      activated,
      title
    } = this.props;

    return <div className="cf-progress-bar-section">
        { activated && <div className="cf-progress-bar-activated">
          <b>{title}</b>
        </div>}
        { !activated && <div className="cf-progress-bar-not-activated">
          {title}
        </div>}
      </div>;
  }
}

ProgressBarSection.propTypes = {
  activated: PropTypes.bool,
  title: PropTypes.string
};
