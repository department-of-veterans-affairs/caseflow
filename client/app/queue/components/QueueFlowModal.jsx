import React from 'react';
import Modal from '../../components/Modal';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { highlightInvalidFormItems } from '../uiReducer/uiActions';

class QueueFlowModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      loading: false
    };
  }

  cancelHandler = () => this.props.onCancel ? this.props.onCancel() : this.props.history.goBack();

  closeHandler = () => this.props.history.replace(this.props.pathAfterSubmit);

  setLoading = (loading) => this.setState({ loading });

  submit = () => {
    const { validateForm } = this.props;

    if (validateForm && !validateForm()) {
      return this.props.highlightInvalidFormItems(true);
    }

    this.props.highlightInvalidFormItems(false);
    this.setState({ loading: true });

    this.props.
      submit().
      then(() => this.closeHandler()).
      finally(() => this.setState({ loading: false }));
  };

  render = () => {
    const { title, button, children } = this.props;

    return (
      <Modal
        title={title}
        buttons={[
          {
            classNames: ['usa-button', 'cf-btn-link'],
            name: COPY.MODAL_CANCEL_BUTTON,
            onClick: this.cancelHandler
          },
          {
            classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
            name: button,
            loading: this.state.loading,
            onClick: this.submit
          }
        ]}
        closeHandler={this.cancelHandler}
      >
        {children}
      </Modal>
    );
  };
}

QueueFlowModal.defaultProps = {
  button: COPY.MODAL_SUBMIT_BUTTON,
  pathAfterSubmit: '/queue',
  title: ''
};

QueueFlowModal.propTypes = {
  children: PropTypes.node,
  highlightInvalidFormItems: PropTypes.func,
  history: PropTypes.object,
  title: PropTypes.string,
  button: PropTypes.string,
  onCancel: PropTypes.func,
  pathAfterSubmit: PropTypes.string,
  // submit should return a promise on which .then() can be called
  submit: PropTypes.func,
  validateForm: PropTypes.func
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      highlightInvalidFormItems
    },
    dispatch
  );

export default withRouter(
  connect(
    null,
    mapDispatchToProps
  )(QueueFlowModal)
);
