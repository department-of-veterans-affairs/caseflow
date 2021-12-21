import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import Alert from './Alert';
import Button from './Button';
import { LoadingIcon } from './icons/LoadingIcon';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import _ from 'lodash';

const alertStyling = css({
  width: '57%'
});

export default class AutoSave extends React.Component {

  constructor(props) {
    super(props);
    this.setIntervalId = null;
    this.state = { showSuccess: false };
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

  debouncedResetSaveStatus = _.debounce(() => {
    this.setState({ showSuccess: true });
    setTimeout(() => this.setState({ showSuccess: false }), this.props.saveSuccessTimeout);
  },
  this.props.saveSuccessTimeout
  );

  componentDidUpdate(prevProps) {
    if (this.props.saveFailed === false && prevProps.saveFailed === true) {
      this.debouncedResetSaveStatus();
    }
  }

  render() {
    if (this.props.isSaving) {
      const color = this.props.spinnerColor || COLORS.GREY_DARK;

      return <div className="saving">
        <div className="loadingSymbol">
          <LoadingIcon
            text="Saving..."
            size={20}
            color={color}
          />
        </div>
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
    } else if (this.state.showSuccess) {
      return <Alert
        message="Connected! Your Daily Docket has been Saved"
        type="success"
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
  saveFailed: PropTypes.bool,
  saveSuccessTimeout: PropTypes.number,
};

AutoSave.defaultProps = {
  intervalInMs: 30000,
  saveSuccessTimeout: 5000
};
