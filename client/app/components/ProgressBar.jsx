import React from 'react';
import PropTypes from 'prop-types';
import ProgressBarSection from './ProgressBarSection';

export default class ProgressBar extends React.Component {
  render() {
    const { sections } = this.props;

    const currentSectionIndex = this.props.sections.findIndex(
      (section) => section.current === true
    );

    return (
      <div className="cf-app-segment">
        <div className="cf-progress-bar" role="progressbar" tabIndex="0">
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
                aria-current="step"
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
