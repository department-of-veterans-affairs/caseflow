import React from 'react';
import PropTypes from 'prop-types';
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

  renderTd = (veteran) => {
    if (veteran.id === null) {
      return (
        <td>{veteran.file_number}</td>
      );
    }

    return (
      <td>
        <a href={`/search?veteran_ids=${veteran.id}`}>{veteran.file_number}</a>
      </td>
    );
  }

  render() {
    const veterans = this.props.veteranRecords;

    veterans.sort((veteranA, veteranB) => {
      if (veteranA.file_number < veteranB.file_number) {
        return -1;
      }
      if (veteranA.file_number > veteranB.file_number) {
        return 1;
      }

      return 0;
    });

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
              <p>Click on the file numbers to search for the veteran.</p>
              <p>If a cell does not have a link the value used in the search url was not found.</p>
              <table>
                <tbody className="test-data-table">
                  {veterans.map((veteran) => (
                    <tr>
                      {this.renderTd(veteran)}
                    </tr>
                  ))}
                </tbody>
              </table>
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
