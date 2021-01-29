import React from 'react';
import PropTypes from 'prop-types';
import Table from '../components/Table';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import NavigationBar from '../components/NavigationBar';
import AppFrame from '../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

export default class TestData extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      currentUser: props.currentUser,
    };
  }

  render() {
    const veteranColumns = [
      {
        header: 'File Number',
        valueFunction: (rec) => (rec.file_number)
      },
      {
        header: 'Description',
        valueFunction: (rec) => (rec.description)
      }
    ];

    const veteranRecords = this.props.veteranRecords;

    return <BrowserRouter>
      <div>
        <NavigationBar
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          appName="Test Users"
          logoProps={{
            accentColor: COLORS.GREY_DARK,
            overlapColor: COLORS.GREY_DARK
          }} />
        <AppFrame>
          <AppSegment filledBackground>
            <h1>Local Veteran Records</h1>
            <div>
              <p>These fake Veteran records are available locally.</p>
              <Table columns={veteranColumns} rowObjects={veteranRecords} />
            </div>
          </AppSegment>
        </AppFrame>
      </div>
    </BrowserRouter>;
  }

}

TestData.propTypes = {
  currentUser: PropTypes.object.isRequired,
  veteranRecords: PropTypes.array.isRequired,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
};
