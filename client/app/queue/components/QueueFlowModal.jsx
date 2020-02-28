import React from 'react';
import Modal from '../../components/Modal';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { highlightInvalidFormItems } from '../uiReducer/uiActions';

import Alert from '../../components/Alert';
import { css } from 'glamor';

const bottomMargin = css({
  marginBottom: '1.5rem'
});

class QueueFlowModal extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      loading: false
    };
  }

  cancelHandler = () => this.props.history.goBack();

  closeHandler = (obj) => {
    const pathAfterSubmit = (obj.pathAfterSubmit) ? obj.pathAfterSubmit : this.props.pathAfterSubmit;

    this.props.history.replace(pathAfterSubmit);
  }

  setLoading = (loading) => this.setState({ loading });

  submit = () => {
    const {
      validateForm
    } = this.props;

    if (validateForm && !validateForm()) {
      return this.props.highlightInvalidFormItems(true);
    }

    this.props.highlightInvalidFormItems(false);
    this.setState({ loading: true });

    this.props.submit().then((obj) => {
      this.setState({ loading: false });
      if (!this.props.error) {
        this.closeHandler(obj);
      }
    }, () => {
      this.setState({ loading: false });
    });
  }

  render = () => {
    const {
      error,
      success,
      title,
      button,
      children
    } = this.props;

    return <Modal
      title={title}
      buttons={[{
        classNames: ['usa-button', 'cf-btn-link'],
        name: COPY.MODAL_CANCEL_BUTTON,
        onClick: this.cancelHandler
      }, {
        classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
        name: button,
        loading: this.state.loading,
        onClick: this.submit
      }]}
      closeHandler={this.cancelHandler}>
      {error &&
        <div {...bottomMargin}>
          <Alert type="error" title={error.title} message={error.detail} />
        </div>
      }
      {success && <div {...bottomMargin}><Alert type="success" title={success.title} message={success.detail} /></div>}
      {children}
    </Modal>;
  }

}

QueueFlowModal.defaultProps = {
  button: COPY.MODAL_SUBMIT_BUTTON,
  pathAfterSubmit: '/queue',
  title: ''
};

QueueFlowModal.propTypes = {
  children: PropTypes.node,
  error: PropTypes.object,
  highlightInvalidFormItems: PropTypes.func,
  history: PropTypes.object,
  title: PropTypes.string,
  button: PropTypes.string,
  pathAfterSubmit: PropTypes.string,
  // submit should return a promise on which .then() can be called
  submit: PropTypes.func,
  success: PropTypes.object,
  validateForm: PropTypes.func,
  reloadPageAfterSubmit: PropTypes.bool
};

const mapStateToProps = (state) => {
  return {
    error: state.ui.messages.error,
    success: state.ui.messages.success
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  highlightInvalidFormItems
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(QueueFlowModal)));

