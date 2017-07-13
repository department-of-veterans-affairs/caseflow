import React from 'react';
import { connect } from 'react-redux';
import ApiUtil from '../util/ApiUtil';
import { onReceiveAssignments, onInitialDataLoadingFail } from './actions';
import { bindActionCreators } from 'redux';
import Table from '../components/Table';
import Link from '../components/Link';
import _ from 'lodash';

class CaseSelect extends React.PureComponent {
  getAssignmentColumn = () => [
    {
      header: 'Veteran',
      valueName: 'veteran_full_name'
    },
    {
      header: 'Veteran ID',
      valueName: 'vbms_id'
    },
    {
      header: 'Issues',
      valueFunction: (appeal) => {
        return (
          <ol>
            {appeal.issues && appeal.issues.map((issue) =>
              issue.levels ? issue.levels.map((level, key) => <li key={key}>{level}</li>) : null)}
          </ol>
        );
      }
    },
    {
      header: 'View claims folder',
      valueFunction: (row) => {
        let buttonText = 'New';
        let buttonType = 'primary';

        if (row.viewed) {
          buttonText = 'Continue';
          buttonType = 'secondary';
        }

        return <Link
            name="view doc"
            button={buttonType}
            to={`/${row.vacols_id}/documents`}>
              {buttonText}
            </Link>;
      }
    }
  ];

  getKeyForRow = (index, row) => row.vacols_id;

  render() {
    if (!this.props.assignments) {
      return null;
    }

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Welcome to Reader!</h1>
          <p className="cf-lead-paragraph">
            Learn more about Reader on our <a href="/reader/help">FAQ page</a>.
          </p>
          <h2>Cases checked in</h2>
          <Table
            className="assignment-list"
            columns={this.getAssignmentColumn}
            rowObjects={this.props.assignments}
            summary="Cases checked in"
            getKeyForRow={this.getKeyForRow}
          />
        </div>
      </div>
    </div>;
  }

  componentDidMount() {
    // We append an unneeded query param to avoid caching the json object. If we get thrown
    // to a page outside of the SPA and then hit back, we want the cached version of this
    // page to be the HTML page, not the JSON object.
    ApiUtil.get('/reader/appeal?json').then((response) => {
      const returnedObject = JSON.parse(response.text);

      this.props.onReceiveAssignments(returnedObject.cases);
    }, this.props.onInitialDataLoadingFail);
  }
}

const mapStateToProps = (state) => _.pick(state, 'assignments');

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onInitialDataLoadingFail,
    onReceiveAssignments
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseSelect);
