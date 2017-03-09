import React, { PropTypes } from 'react';
import ProgressBarSection from './ProgressBarSection';

/**
 * Sections must be passed as a prop in this format:
 *    [
 *      { 'title' : string, 'activated' : boolean }
 *    ]
 */
export default class ProgressBar extends React.Component {
  render() {
    let {
      sections
    } = this.props;

    return <div className="cf-app-segment">
      <div className="cf-progress-bar">
        {sections.map((section, i) => {
          return <ProgressBarSection
            activated={section.activated}
            key={i}
            title={section.title}
          />;
        })}
      </div>
    </div>;
  }
}

ProgressBar.propTypes = {
  sections: PropTypes.arrayOf(PropTypes.object)
};
