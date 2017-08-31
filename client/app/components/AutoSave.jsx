import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { loadingSymbolHtml } from '../components/RenderFunctions.jsx';
import { LOADING_INDICATOR_COLOR_DEFAULT } from '../constants/AppConstants';
import moment from 'moment';

// This may go away in favor of the timestamp from updated record
const now = () => {
  return moment().
    format('h:mm a').
    replace(/(p|a)m/, '$1.m.');
};

export class AutoSave extends React.Component {

  componentDidMount = () => {
    if (!window.onbeforeunload) {
      window.onbeforeunload = () => {
        this.props.save(this.props.saveFunction);
      };
    }

    setInterval(() => {
      this.props.save(this.props.saveFunction);
    }, this.props.intervalInMs || 30000);
  }

  render() {
    if (this.props.isSaving) {
      const color = this.props.spinnerColor || LOADING_INDICATOR_COLOR_DEFAULT;

      return <div className="saving">Saving...
        <div className="loadingSymbol">{loadingSymbolHtml('', '100%', color)}</div>
      </div>;
    }

    return <span className="saving">Last saved at {now()}</span>;
  }
}

const mapStateToProps = (state) => ({
  isSaving: state.isSaving
});

const mapDispatchToProps = (dispatch) => ({
  doBeforeWindowCloses: () => {
    dispatch(this.props.beforeWindowClosesActionCreator());
  },
  save: (saveFunction) => {
    saveFunction(dispatch);
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(AutoSave);

AutoSave.propTypes = {
  isSaving: PropTypes.bool,
  spinnerColor: PropTypes.string,
  intervalInMs: PropTypes.number,
  saveFunction: PropTypes.func.isRequired
};
