import React from 'react';
import { Link } from 'react-router-dom';
import Modal from '../components/Modal';
import Button from '../components/Button';
import CancelCertificationModal from './CancelCertificationModal'




// TODO: use the footer (see ConfirmHearing.jsx) everywhere,
// then delete this comment :)
export default class Footer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      modal: false,
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
      nextPageUrl,
      certificationId
    } = this.props;

    return <div>
      <Button
            name="Cancel Certification"
            onClick={this.handleModalOpen}
            classNames={["cf-btn-link"]}
      />
      <Link to={nextPageUrl}>
        <button type="button" className="cf-push-right">
          Continue
        </button>
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
