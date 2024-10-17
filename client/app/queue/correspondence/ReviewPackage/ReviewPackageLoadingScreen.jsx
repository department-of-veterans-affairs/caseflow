import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../../../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../../../constants/AppConstants';
import ApiUtil from '../../../util/ApiUtil';

import {
  setCorrespondence,
  setTaskInstructions
} from '../correspondenceReducer/reviewPackageActions';
import WindowUtil from '../../../util/WindowUtil';

class ReviewPackageLoadingScreen extends React.PureComponent {

  createLoadPromise = async () => {
    return await ApiUtil.get(
      `/queue/correspondence/${this.props.correspondence_uuid}/review_package`).then(
      (response) => {
        /* eslint-disable no-unused-vars, camelcase */
        const {
          correspondence,
          general_information,
          taskInstructions
        } = response.body;

        this.props.setCorrespondence(correspondence);
        this.props.setTaskInstructions(taskInstructions);
      }
    );
  }

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this correspondence<br />
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading review package...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load correspondence'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div className="usa-grid">
      {loadingDataDisplay}
    </div>;
  };
}

ReviewPackageLoadingScreen.propTypes = {
  correspondence_uuid: PropTypes.string,
  children: PropTypes.node,
  setCorrespondence: PropTypes.func,
  setTaskInstructions: PropTypes.func
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setCorrespondence,
  setTaskInstructions
}, dispatch);

export default (connect(null, mapDispatchToProps)(ReviewPackageLoadingScreen));
