// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';

import { setSpecialIssues } from './QueueActions';

type Params = {|
  children: React.Node,
  appealExternalId: number
|};

type Props = Params & {|
  // Action creators
  setSpecialIssues: typeof setSpecialIssues
|};

class SpecialIssueLoadingScreen extends React.PureComponent<Props> {
  createLoadPromise = () => ApiUtil.get(
    `/appeals/${this.props.appealExternalId}/special_issues`, { timeout: { response: 5 * 60 * 1000 } }).then(
    (response) => {
      // eslint-disable-next-line no-unused-vars
      const { appeal_id, id, ...specialIssues } = JSON.parse(response.text);

      this.props.setSpecialIssues(specialIssues);
    }
  );

  reload = () => window.location.reload();

  render = () => {
    const failStatusMessageChildren = <div>
      It looks like Caseflow was unable to load this case's special issues<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading cases...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load special issues'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div className="usa-grid">
      {loadingDataDisplay}
    </div>;
  };
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setSpecialIssues
}, dispatch);

export default (connect(null, mapDispatchToProps)(SpecialIssueLoadingScreen): React.ComponentType<Params>);
