import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ProgressBarSection from './ProgressBarSection';

export default class ProgressBar extends React.Component {
  render() {
    let { sections } = this.props;

    let currentSectionIndex = this.props.sections.findIndex(
      (section) => section.current === true
    );

    return (
      <div role="progressbar" className="cf-app-segment">
        <div className="cf-progress-bar">
          {sections.map((section, i) => {
            if (i <= currentSectionIndex) {
              section.activated = true;
            } else {
              section.activated = false;
            }

            return (
              <ProgressBarSection
                activated={section.activated}
                key={i}
                title={section.title}
              />
            );
          })}
        </div>
      </div>
    );
  }
}

ProgressBar.propTypes = {
  sections: PropTypes.arrayOf(
    PropTypes.shape({
      activated: PropTypes.bool,
      title: PropTypes.string,
    })
  ),
};
