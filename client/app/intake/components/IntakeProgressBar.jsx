import React from 'react';
import { Route } from 'react-router-dom';
import ProgressBar from '../../components/ProgressBar';
import { PAGE_PATHS } from '../constants';
import _ from 'lodash';

class IntakeProgressBarInner extends React.PureComponent {
  render() {
    const progressBarSections = [
      {
        title: '1. Begin Intake',
        path: PAGE_PATHS.BEGIN
      },
      {
        title: '2. Review Request',
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

    const progressBarSectionsWithCurrentMarked = progressBarSections.map((section) =>
      _({ current: section.path === this.props.location.pathname }).
        merge(section).
        omit('path').
        value()
    );

    return <ProgressBar sections={progressBarSectionsWithCurrentMarked} />;
  }
}

export default class IntakeProgressBar extends React.Component {
  render = () => <Route path="/" component={IntakeProgressBarInner} />;
}
