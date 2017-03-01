import React, { PropTypes } from 'react';

export default class BackButton extends React.Component {
  componentDidMount() {
    if (this.props.type === 'submit') {
      console.warn(`Warning! You are using a button with type submit.
        Was this intended? Make sure to use event.preventDefault() if
        you're using it with a form and an onClick handler`);
    }
  }

  render() {
    let {
      classNames,
      children,
      name,
      type
    } = this.props;

    if (!children) {
      children = name;
    }

    let goBack = () => {
      history.go(-1);
    };

    return <span>
      <button
        className={classNames.join(' ')}
        type={type}
        onClick={goBack}>
          {children}
      </button>
    </span>;
  }
}

BackButton.defaultProps = {
  classNames: ['cf-btn-link'],
  type: 'button'
};

BackButton.propTypes = {
  children: PropTypes.node,
  classNames: PropTypes.arrayOf(PropTypes.string),
  linkStyle: PropTypes.bool,
  name: PropTypes.string.isRequired,
  type: PropTypes.string
};
