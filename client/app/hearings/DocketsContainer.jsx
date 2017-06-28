import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import { loadingSymbolHtml } from '../components/RenderFunctions.jsx';
import Dockets from './Dockets';
import ApiUtil from '../util/ApiUtil';

export const getDockets = (dispatch) => {
  ApiUtil.get('/hearings/dockets.json', { cache: true }).
    then((response) => {
      dispatch(Actions.populateDockets(response.body));
      dispatch(Actions.docketsAreLoaded());
    }/* , (err) => {
      //dispatch(handleServerError(err));
      console.log('hearings/dockets.json ERROR', new Date());
    }*/);
};

export class DocketsContainer extends React.Component {

  componentDidMount = () => {
    if (!this.props.docketsLoaded) {
      setTimeout(() => {
        this.props.getDockets();
      }, 600);
    }
  }

  render() {

    if (!this.props.docketsLoaded) {
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
  docketsLoaded: state.docketsLoaded,
  app: state.app
});

const mapDispatchToProps = (dispatch) => ({
  // TODO: pass dispatch into method and use it
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
  dockets: PropTypes.object.isRequired,
  docketsLoaded: PropTypes.bool
  // dockets: PropTypes.arrayOf(PropTypes.object).isRequired
};
