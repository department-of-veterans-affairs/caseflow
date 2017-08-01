import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { loadingSymbolHtml } from '../components/RenderFunctions.jsx';
import moment from 'moment';

// This may go away in favor of the timestamp from updated record
const now = () => {
  return moment().
    format('h:mm a').
    replace(/(p|a)m/, '$1.m.');
};

export class AutosavePrompt extends React.Component {
  render() {
    const color = this.props.spinnerColor || '#323a45';

    if (this.props.saving) {
      return <div className="saving">Saving...
        <div className="loadingSymbol">{loadingSymbolHtml('', '100%', color)}</div>
      </div>;
    }

    return <span className="saving">Last saved at {now()}</span>;

  }
}

const mapStateToProps = (state) => ({
  saving: state.saving
});

export default connect(
  mapStateToProps
)(AutosavePrompt);

AutosavePrompt.propTypes = {
  saving: PropTypes.bool
};
