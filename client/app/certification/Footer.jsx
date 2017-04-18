import React from 'react';
import { Link } from 'react-router-dom';
import Button from '../components/Button';
import CancelCertificationModal from './CancelCertificationModal';

/*
 * Caseflow Certification Footer.
 * Shared between all Certification v2 pages.
 * Handles the display of the cancel certiifcation modal.
 *
 */
export default class Footer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      modal: false
    };
  }

  handleModalOpen = () => {
    this.setState({ modal: true });
  };

  handleModalClose = () => {
    this.setState({ modal: false });
  };

  render() {
    let cancelModalDisplay = this.state.modal;
    let {
      certificationId,
      loading,
      disableContinue,
      onClickContinue,
      nextPageUrl
    } = this.props;

    return <div className="cf-app-segment">
      <Button
            name="Cancel Certification"
            onClick={this.handleModalOpen}
            classNames={["cf-btn-link"]}
      />
      <Link to={nextPageUrl || '#'}>
        <Button type="button"
          name="Continue"
          classNames={["cf-push-right"]}
          onClick={onClickContinue}
          loading={loading}
          disabled={disableContinue}>
          Continue
        </Button>
      </Link>
      {cancelModalDisplay && <CancelCertificationModal
        title="Cancel Certification"
        certificationId={certificationId}
        closeHandler={this.handleModalClose}>
      </CancelCertificationModal>
      }
    </div>;
  }
}
