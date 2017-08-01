import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { handleServerError } from './actions/hearings';
import { populateDockets } from './actions/dockets';
import { loadingSymbolHtml } from '../components/RenderFunctions.jsx';
import Dockets from './Dockets';
import ApiUtil from '../util/ApiUtil';

export const getDockets = (dispatch) => {
  ApiUtil.get('/hearings/dockets.json', { cache: true }).
    then((response) => {
      dispatch(populateDockets(response.body));
    }, (err) => {
      dispatch(handleServerError(err));
    });
};

export class DocketsContainer extends React.Component {

  componentDidMount() {
    if (!this.props.dockets) {
      this.props.getDockets();
    }

    // Since the title may have changed before rendering...
    const pageTitle = document.getElementById('page-title');

    if (pageTitle) {
      pageTitle.innerHTML = '';
    }
  }

  render() {

    if (this.props.serverError) {
      return <div style={{ textAlign: 'center' }}>
        An error occurred while retrieving your hearings.</div>;
    }

    if (!this.props.dockets) {
      return <div className="loading-dockets">
        <div>{loadingSymbolHtml('', '50%', '#68bd07')}</div>
        <div>Loading dockets, please wait...</div>
      </div>;
    }

    if (Object.keys(this.props.dockets).length === 0) {
      return <div>You have no upcoming hearings.</div>;
    }

    return <Dockets {...this.props} />;
  }
}

const mapStateToProps = (state) => ({
  dockets: state.dockets,
  serverError: state.serverError
});

const mapDispatchToProps = (dispatch) => ({
  getDockets: () => {
    getDockets(dispatch);
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DocketsContainer);

DocketsContainer.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  dockets: PropTypes.object,
  serverError: PropTypes.object
};
