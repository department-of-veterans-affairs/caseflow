import React from 'react';
import { Link } from 'react-router-dom';
import Modal from '../components/Modal';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField';


// TODO: use the footer (see ConfirmHearing.jsx) everywhere,
// then delete this comment :)
export default class Footer extends React.Component {
  constructor(props) {
    super(props);
    window.jqueryOn = false;

    this.state = { modal: false };
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
      nextPageUrl
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
      {cancelModalDisplay && <Modal
            buttons={[
              { classNames: ["cf-modal-link", "cf-btn-link"],
                name: '\u226A Go back',
                onClick: this.handleModalClose
              },
              { classNames: ["usa-button", "usa-button-secondary"],
                name: 'Cancel certification',
                onClick: this.handleModalClose
              }
            ]}
            visible={true}
            closeHandler={this.handleModalClose}
            title="Cancel Certification">
            <p>
              Please explain why this case cannot be certified with Caseflow. Once you click Cancel certification, changes made to this case in Caseflow will not be saved.
            </p>
        </Modal>}
    </div>;
  }
}
