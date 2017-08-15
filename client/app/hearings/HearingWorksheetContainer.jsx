import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import { loadingSymbolHtml } from '../components/RenderFunctions.jsx';
import HearingWorksheet from './HearingWorksheet';
import ApiUtil from '../util/ApiUtil';

// TODO: method should get data to populate worksheet
export const getWorksheet = (id, dispatch) => {
  ApiUtil.get(`/hearings/${id}/worksheet.json`, { cache: true }).
    then((response) => {
      dispatch(Actions.populateWorksheet(response.body));
    }, (err) => {
      dispatch(Actions.handleServerError(err));
    });
};

export class HearingWorksheetContainer extends React.Component {

  componentDidMount() {
    // TODO: if !worksheet call this.props.getWorksheet
    if (!this.props.worksheet) {
      this.props.getWorksheet(this.props.hearingId);
    }

    // Since the page title does not change when react router
    // renders this component...
    const pageTitle = document.getElementById('page-title');

    if (pageTitle) {
      pageTitle.innerHTML = ' | Daily Docket | Hearing Worksheet';
    }
  }

  render() {

    if (this.props.serverError) {
      return <div style={{ textAlign: 'center' }}>
        An error occurred while retrieving your hearings.</div>;
    }

    if (!this.props.worksheet) {
      return <div className="loading-dockets">
        <div>{loadingSymbolHtml('', '50%', '#68bd07')}</div>
        <div>Loading worksheet, please wait...</div>
      </div>;
    }

    return <HearingWorksheet
      hearingType="Video"
      worksheet={this.props.worksheet}
      {...this.props}
    />;
  }
}

const mapStateToProps = (state) => ({
  // TODO: add mappings
  worksheet: state.worksheet
});

const mapDispatchToProps = (dispatch) => ({
  getWorksheet: (id) => {
    getWorksheet(id, dispatch);
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetContainer);

HearingWorksheetContainer.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  hearingId: PropTypes.string.isRequired
};
