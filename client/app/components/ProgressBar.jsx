import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from './AppSegment';
import ProgressBarSection from './ProgressBarSection';

export default class ProgressBar extends React.Component {
  render() {
    let {
      sections
    } = this.props;

    let currentSectionIndex = this.props.sections.findIndex(
      (section) => section.current === true
    );

    return <AppSegment>
      <div className="cf-progress-bar">
        {sections.map((section, i) => {
          if (i <= currentSectionIndex) {
            section.activated = true;
          } else {
            section.activated = false;
          }

          return <ProgressBarSection
            activated={section.activated}
            key={i}
            title={section.title}
          />;
        })}
      </div>
    </AppSegment>;
  }
}

ProgressBar.propTypes = {
  sections: PropTypes.arrayOf(
    PropTypes.shape({
      activated: PropTypes.boolean,
      title: PropTypes.string
    })
  )
};
