import React from 'react';
import { connect } from 'react-redux';
import { Route } from 'react-router-dom';
import ProgressBar from '../../components/ProgressBar';
import { PAGE_PATHS } from '../constants';
import _ from 'lodash';

class IntakeProgressBarInnerUnconnected extends React.PureComponent {
  render() {
    let progressBarSections;

    if (this.props.featureToggles.reentryForm) {
      progressBarSections = [
        {
          title: '1. Select Form',
          path: PAGE_PATHS.BEGIN
        },
        {
          title: '2. Search',
          path: PAGE_PATHS.SEARCH
        },
        {
          title: '3. Review',
          path: PAGE_PATHS.REVIEW
        },
        {
          title: '4. Finish',
          path: PAGE_PATHS.FINISH
        },
        {
          title: '5. Confirmation',
          path: PAGE_PATHS.COMPLETED
        }
      ];
    } else {
      progressBarSections = [
        {
          title: '1. Begin Intake',
          path: PAGE_PATHS.BEGIN
        },
        {
          title: '2. Review Election',
          path: PAGE_PATHS.REVIEW
        },
        {
          title: '3. Finish Processing',
          path: PAGE_PATHS.FINISH
        },
        {
          title: '4. Confirmation',
          path: PAGE_PATHS.COMPLETED
        }
      ];
    }

    const progressBarSectionsWithCurrentMarked = progressBarSections.map((section) =>
      _({ current: section.path === this.props.location.pathname }).
        merge(section).
        omit('path').
        value()
    );

    return <ProgressBar sections={progressBarSectionsWithCurrentMarked} />;
  }
}

const IntakeProgressBarInner = connect(
  ({ intake }) => ({ featureToggles: intake.featureToggles })
)(IntakeProgressBarInnerUnconnected);

export default class IntakeProgressBar extends React.Component {
  render = () => <Route path="/" component={IntakeProgressBarInner} />;
}
