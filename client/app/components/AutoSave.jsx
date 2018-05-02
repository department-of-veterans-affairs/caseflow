import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import Alert from './Alert';
import Button from './Button';
import { loadingSymbolHtml } from '../components/RenderFunctions';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

const alertStyling = css({
  width: '57%'
});

export default class AutoSave extends React.Component {

  constructor(props) {
    super(props);
    this.setIntervalId = null;
  }

  save() {
    if (!this.props.saveFailed) {
      this.props.save();
    }
  }

  componentDidMount() {
    if (!window.onbeforeunload) {
      window.onbeforeunload = () => {
        this.props.save();
      };
    }

    this.setIntervalId = setInterval(() => this.save(), this.props.intervalInMs);
  }

  componentWillUnmount() {
    this.props.save();
    clearInterval(this.setIntervalId);
  }

  render() {
    if (this.props.isSaving) {
      const color = this.props.spinnerColor || COLORS.GREY_DARK;

      return <div className="saving">
        <div className="loadingSymbol">{loadingSymbolHtml('Saving...', '20px', color)}</div>
      </div>;
    }

    if (this.props.saveFailed) {

      const alertMessage = <div>
        Unable to save. Please check your internet connection and try again. <span>
          <Button
            name="RETRY"
            onClick={this.props.save}
            linkStyling
          />
        </span>
      </div>;

      return <Alert
        message={alertMessage}
        type="error"
        fixed
        styling={alertStyling}
      />;
    }

    return <span className="saving">Last saved at {this.props.timeSaved}</span>;
  }
}

AutoSave.propTypes = {
  isSaving: PropTypes.bool,
  spinnerColor: PropTypes.string,
  intervalInMs: PropTypes.number,
  save: PropTypes.func.isRequired,
  timeSaved: PropTypes.string.isRequired,
  saveFailed: PropTypes.bool
};

AutoSave.defaultProps = {
  intervalInMs: 30000
};
