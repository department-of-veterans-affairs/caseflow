import React from 'react';
import PropTypes from 'prop-types';
import { loadingSymbolHtml } from '../components/RenderFunctions';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import moment from 'moment';

const now = () => {
  return moment().tz('America/New_York').
    format('h:mm a');
};

export default class AutoSave extends React.Component {

  constructor(props) {
    super(props);
    this.setIntervalId = null;
  }

  componentDidMount() {
    if (!window.onbeforeunload) {
      window.onbeforeunload = () => {
        this.props.save();
      };
    }

    this.setIntervalId = setInterval(() => this.props.save(), this.props.intervalInMs);
  }

  componentWillUnmount() {
    this.props.save();
    clearInterval(this.setIntervalId);
  }

  render() {
    console.log('do we ever get in here?');
    if (this.props.isSaving) {
      const color = this.props.spinnerColor || COLORS.GREY_DARK;

      return <div className="saving">Saving...
        <div className="loadingSymbol">{loadingSymbolHtml('', '100%', color)}</div>
      </div>;
    }

    if (this.props.saveFailed) {
      return <span className="saving">Save failed.</span>;
    }

    return <span className="saving">Last saved at {now()}</span>;
  }
}

AutoSave.propTypes = {
  isSaving: PropTypes.bool,
  spinnerColor: PropTypes.string,
  intervalInMs: PropTypes.number,
  save: PropTypes.func.isRequired,
  saveFailed: PropTypes.bool
};

AutoSave.defaultProps = {
  intervalInMs: 30000
};
