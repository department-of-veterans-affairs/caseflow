import React, { PropTypes } from 'react';

// components
import Alert from '../components/Alert';

// container components
import EstablishClaim from './EstablishClaimPage/EstablishClaim';
import StyleGuideIndex from './StyleGuide/StyleGuideIndex';
import StyleGuideModal from './StyleGuide/StyleGuideModal';
import StyleGuideTabs from './StyleGuide/StyleGuideTabs';
import CaseWorkerIndex from './CaseWorker/CaseWorkerIndex';
import TasksManagerIndex from './TasksManager/TasksManagerIndex';
import TestPage from './TestPage';
import DecisionReviewer from '../reader/DecisionReviewer';
import EstablishClaimComplete from './EstablishClaimPage/EstablishClaimComplete';
import UnpreparedTasksIndex from './UnpreparedTasksIndex';

const Pages = {
  CaseWorkerIndex,
  DecisionReviewer,
  EstablishClaim,
  EstablishClaimComplete,
  StyleGuideIndex,
  StyleGuideModal,
  StyleGuideTabs,
  TasksManagerIndex,
  TestPage,
  UnpreparedTasksIndex
};

// This is the "base page" that wraps all pages rendered directly
// in a Rails view. This component manages interactivity that exists
// across *all* React page. For now that includes:
//   - alerts
//
// The `page` property dictates which page is rendered within this
// component. e.g.  <BaseContainer page="EstablishClaim" />

export default class BaseContainer extends React.Component {
  constructor(props) {
    super(props);
    window.jqueryOn = false;

    this.state = { alert: null };
  }

  handleAlert = (type, title, message) => {
    this.setState({
      alert: {
        message,
        title,
        type
      }
    });
  }

  handleAlertClear = () => {
    this.setState({ alert: null });
  }

  render() {
    // `rest` signifies all the props passed in from Rails that
    // we want to send directly to the PageComponent
    let {
      page,
      ...rest
    } = this.props;

    let {
      alert
    } = this.state;

    let PageComponent = Pages[page];

    return <div>
      {alert && <Alert
        type={alert.type}
        title={alert.title}
        message={alert.message}
        handleClear={this.handleAlertClear}
      />}
      <PageComponent
        {...rest}
        handleAlert={this.handleAlert}
        handleAlertClear={this.handleAlertClear}
      />
    </div>;
  }
}

BaseContainer.propTypes = {
  page: PropTypes.string.isRequired
};
