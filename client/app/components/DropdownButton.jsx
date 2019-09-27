import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';

const dropdownList = css({
  top: '3.55rem',
  left: '0',
  width: '21.2rem'
});
const dropdownBtn = css({
  marginRight: '0rem'
});
const dropdownBtnContainer = css({
  marginRight: '2rem'
});

export default class DropdownButton extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      menu: false
    };
    this.wrapperRef = null;
  }

  componentDidMount = () => {
    document.addEventListener('keydown', this.keyHandler);
    document.addEventListener('mousedown', this.onClickOutside);
  }

  componentWillUnmount = () => {
    document.removeEventListener('mousedown', this.onClickOutside);
    document.removeEventListener('keydown', this.keyHandler);
  }
  setWrapperRef = (node) => this.wrapperRef = node

  onClickOutside = (event) => {
    if (this.wrapperRef && !this.wrapperRef.contains(event.target) && this.state.menu) {
      this.setState({
        menu: false
      });
    }
  }

  keyHandler = (event) => {
    if (event.key === 'Escape') {
      this.setState({
        menu: false
      });
    } else if (event.key === 'Enter' || event.key === ' ') {
      this.setState((prevState) => ({
        menu: !prevState.menu
      }));
      event.preventDefault();
    }
  }
  onMenuClick = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  dropdownLink = (list) => {
    return <Link className="usa-button-secondary usa-button">
      href={list.target}>{list.title}</Link>;
  }

  dropdownAction = (list) => {
    return <a onClick={() => {
      if (this.props.onClick) {
        this.props.onClick(list.value);
      }
      this.onMenuClick();
    }}>{list.title}</a>;
  }

  dropdownButtonList = () => {
    return <ul className="cf-dropdown-menu active" {...dropdownList} aria-pressed="true" aria-haspopup="true">
      {this.props.lists.map((list, index) =>
        <li key={index} role="menuitem" tabIndex="0" >
          {list.target ? this.dropdownLink(list) : this.dropdownAction(list)}
        </li>)}
    </ul>;
  };

  render() {
    const { label } = this.props;

    return <div className="cf-dropdown" ref={this.setWrapperRef} {...dropdownBtnContainer} aria-haspopup="true">
      <a {...dropdownBtn}
        onClick={this.onMenuClick}
        className="cf-dropdown-trigger usa-button usa-button-secondary" tabIndex="0" role="button menu">
        {label}
      </a>
      {this.state.menu && this.dropdownButtonList() }
    </div>;
  }
}

DropdownButton.propTypes = {
  list: PropTypes.arrayOf(PropTypes.oneOfType([
    PropTypes.shape({
      title: PropTypes.string.isRequired,
      target: PropTypes.string.isRequired
    }),
    PropTypes.shape({
      title: PropTypes.string.isRequired,
      value: PropTypes.any.isRequired
    })
  ])),
  onClick: PropTypes.func,
  label: PropTypes.string.isRequired
};
