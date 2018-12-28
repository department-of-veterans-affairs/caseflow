import React from 'react';
import Modal from '../../components/Modal';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { highlightInvalidFormItems } from '../uiReducer/uiActions';

import Alert from '../../components/Alert';
import { css } from 'glamor';

const bottomMargin = css({
  marginBottom: '1.5rem'
});

export default function editModalBase(ComponentToWrap, { title, button, pathAfterSubmit, propsToText }) {
  class WrappedComponent extends React.Component {
    constructor(props) {
      super(props);

      this.state = { loading: false };
    }

    getWrappedComponentRef = (ref) => this.wrappedComponent = ref;

    cancelHandler = () => {
      this.props.history.goBack();
    }

    pathAfterSubmit = () => pathAfterSubmit || (propsToText && propsToText(this.props).pathAfterSubmit) || '/queue';

    closeHandler = () => {
      this.props.history.replace(this.pathAfterSubmit());
    }

    title = () => title || (propsToText && propsToText(this.props).title);

    button = () => button || (propsToText && propsToText(this.props).button) || 'Submit';

    setLoading = (loading) => this.setState({ loading });

    submit = () => {
      const {
        validateForm: validation = null
      } = this.wrappedComponent;

      if (validation && !validation()) {
        return this.props.highlightInvalidFormItems(true);
      }
      this.props.highlightInvalidFormItems(false);

      this.setState({ loading: true });

      this.wrappedComponent.submit().then(() => {
        this.setState({ loading: false });
        if (!this.props.error) {
          this.closeHandler();
        }
      }, () => {
        this.setState({ loading: false });
      });
    }

    render = () => {
      const { error } = this.props;

      return <Modal
        title={this.title()}
        buttons={[{
          classNames: ['usa-button', 'cf-btn-link'],
          name: 'Cancel',
          onClick: this.cancelHandler
        }, {
          classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
          name: this.button(),
          loading: this.state.loading,
          onClick: this.submit
        }]}
        closeHandler={this.cancelHandler}>
        {error &&
          <div {...bottomMargin}>
            <Alert type="error" title={error.title} message={error.detail} />
          </div>
        }
        <ComponentToWrap ref={this.getWrappedComponentRef} setLoading={this.setLoading} {...this.props} />
      </Modal>;
    }
  }

  const mapStateToProps = (state) => {
    return {
      error: state.ui.messages.error
    };
  };

  const mapDispatchToProps = (dispatch) => bindActionCreators({
    highlightInvalidFormItems
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
