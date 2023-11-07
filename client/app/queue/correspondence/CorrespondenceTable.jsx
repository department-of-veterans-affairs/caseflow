import React from 'react';
import QueueTable from '../QueueTable';
import PropTypes from 'prop-types';
import ApiUtil from '../../../app/util/ApiUtil';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { loadVetCorrespondence } from './correspondenceReducer/correspondenceActions';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

class CorrespondenceTable extends React.Component {

  // grabs correspondences and loads into intakeCorrespondence redux store.
  getVeteransWithCorrespondence() {
    return ApiUtil.get('/queue/correspondence?json').then((response) => {
      const returnedObject = response.body;
      const vetCorrespondences = returnedObject.vetCorrespondences;

      this.props.loadVetCorrespondence(vetCorrespondences);
    }).
      catch((err) => {
        // allow HTTP errors to fall on the floor via the console.
        console.error(new Error(`Problem with GET /queue/correspondence?json ${err}`));
      });
  }

  // load veteran correspondence info on page load
  componentDidMount() {
    this.getVeteransWithCorrespondence();
  }
  render() {
    // test data names link to multi_correspondence.rb seed data
    const testobj = [{
      veteranDetails: 'Adam West (66555444)',
      packageDocumentType: '1111111',
      cmPacketNumber: '22222222',
      correspondeceId: 11,
    },
    {
      veteranDetails: 'Michael Keaton (67555444)',
      packageDocumentType: '12345678',
      cmPacketNumber: '12345679',
      correspondeceId: 2,
    }];

    const columns = [
      {
        name: 'veteranDetails',
        header: 'Veteran Details',
        align: 'left',
        valueName: 'veteranDetails',
        getSortValue: (row) => row.veteranDetails,
        backendCanSort: true,
        valueFunction: (row) => (
          <Link href={`/queue/correspondence/${row.correspondeceId}/review_package`}>
            {row.veteranDetails}
          </Link>
        )
      },
      {
        name: 'packageDocumentType',
        header: 'Package Document Type ',
        align: 'left',
        valueName: 'packageDocumentType',
        enableFilter: true,
        getSortValue: (row) => row.packageDocumentType,
        backendCanSort: true
      },
      {
        name: 'cmPacketNumber',
        header: 'CM Packet Number ',
        align: 'left',
        valueName: 'cmPacketNumber',
        getSortValue: (row) => row.cmPacketNumber,
        backendCanSort: true
      }
    ];
    const tabPaginationOptions = {
      onPageLoaded: this.onPageLoaded
    };

    return (
      <QueueTable
        className="assign-correspondence-table"
        columns={columns}
        rowObjects={testobj}
        summary="scheduled-hearings-table"
        enablePagination
        tabPaginationOptions={tabPaginationOptions}
      />
    );
  }
}

CorrespondenceTable.propTypes = {
  hearingScheduleColumns: PropTypes.array,
  hearingScheduleRows: PropTypes.array,
  onApply: PropTypes.func,
  loadVetCorrespondence: PropTypes.func,
  vetCorrespondences: PropTypes.array,
  history: PropTypes.object,
  user: PropTypes.shape({
    userCanBuildHearingSchedule: PropTypes.bool
  })
};

const mapStateToProps = (state) => ({
  vetCorrespondences: state.intakeCorrespondence.vetCorrespondences
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    loadVetCorrespondence
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceTable);
