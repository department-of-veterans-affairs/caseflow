import React from 'react';
import { Link } from 'react-router-dom';
import Button from '../components/Button';
import CancelCertificationModal from './CancelCertificationModal';
import { connect } from 'react-redux';
import * as certificationActions from './actions/Certification';

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
    let {
      loading,
      disableContinue,
      hideContinue,
      onClickContinue,
      buttonText,
      nextPageUrl,
      certificationId,
      showCancellationModal
    } = this.props;


    return <div className="cf-app-segment">
      <Button
        name="Cancel Certification"
        onClick={this.handleModalOpen}
        classNames={['cf-btn-link']}
      />
      { !hideContinue && <Link to={nextPageUrl || '#'}>
        <Button type="button"
          name="Continue"
          classNames={['cf-push-right']}
          onClick={onClickContinue}
          loading={loading}
          disabled={disableContinue}>
          { buttonText ? buttonText : 'Continue' }
        </Button>
      </Link>
      }
      {showCancellationModal && <CancelCertificationModal
        title="Cancel Certification"
        certificationId={certificationId}
        closeHandler={this.handleModalClose}>
      </CancelCertificationModal>
      }
    </div>;
  }
}

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

