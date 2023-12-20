import React from 'react';
import PropTypes from 'prop-types';
import { useHistory } from 'react-router';
import Button from '../components/Button';
import CancelCertificationModal from './CancelCertificationModal';
import { connect } from 'react-redux';
import * as certificationActions from './actions/Certification';

const ContinueButton = ({ disabled, loading, onClick, text, link }) => {
  const { push } = useHistory();

  return (
    <Button
      type="button"
      name="Continue"
      classNames={['cf-push-right']}
      onClick={link ? () => push(link) : onClick}
      loading={loading}
      disabled={disabled}
    >
      {text ? text : 'Continue'}
    </Button>
  );
};

ContinueButton.propTypes = {
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  onClick: PropTypes.func,
  text: PropTypes.string,
  link: PropTypes.string
};

/*
 * Caseflow Certification Footer.
 * Shared between all Certification v2 pages.
 * Handles the display of the cancel certiifcation modal.
 *
 */
export class Footer extends React.Component {
  handleModalOpen = () => {
    this.props.toggleCancellationModal();
  };

  handleModalClose = () => {
    this.props.toggleCancellationModal();
  };

  render() {
    const {
      loading,
      disableContinue,
      hideContinue,
      onClickContinue,
      buttonText,
      nextPageUrl,
      certificationId,
      showCancellationModal
    } = this.props;

    return (
      <div className="cf-app-segment">
        <Button
          name="Cancel Certification"
          onClick={this.handleModalOpen}
          classNames={['cf-btn-link']}
        />
        {!hideContinue && (
          <ContinueButton
            loading={loading}
            disabled={disableContinue}
            onClick={onClickContinue}
            link={nextPageUrl}
            text={buttonText}
          />
        )}
        {showCancellationModal && (
          <CancelCertificationModal
            title="Cancel Certification"
            certificationId={certificationId}
            closeHandler={this.handleModalClose}
          />
        )}
      </div>
    );
  }
}

Footer.propTypes = {
  loading: PropTypes.bool,
  disableContinue: PropTypes.bool,
  hideContinue: PropTypes.bool,
  onClickContinue: PropTypes.func,
  buttonText: PropTypes.string,
  nextPageUrl: PropTypes.string,
  certificationId: PropTypes.number,
  showCancellationModal: PropTypes.bool,
  toggleCancellationModal: PropTypes.func
};

const mapDispatchToProps = (dispatch) => ({
  toggleCancellationModal: () => {
    dispatch(certificationActions.toggleCancellationModal());
  }
});

const mapStateToProps = (state) => ({
  certificationId: state.certificationId,
  showCancellationModal: state.showCancellationModal
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Footer);
