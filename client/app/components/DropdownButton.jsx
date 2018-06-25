import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';

export default class DropdownButton extends React.Component {
  constructor(props) {
    super(props);

    this.wrapperRef = null;
    this.state = {
      menu: false
    };
  }

  setWrapperRef = (node) => this.wrapperRef = node

  onClick = (title) => () => {
  }

  onMenuClick = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  render() {
    const {
      label,
      lists
    } = this.props;

    const dropdownButtonList = () => {
      return <ul className="cf-dropdown-menu active"
        aria-labelledby="menu-trigger">
        {lists.map((list, index) =>
          <li key={index}>
            <Link className="usa-button-outline usa-button"
              href={list.target}
              onClick={this.onClick(list.title)}>{list.title}</Link>
          </li>)}
      </ul>;
    };

    return <div ref={this.setWrapperRef} className="cf-dropdown">
      <a href="#dropdown-menu"
        className="cf-dropdown-trigger usa-button usa-button-outline"
        onClick={this.onMenuClick}>
        {label}
      </a>
      {this.state.menu && dropdownButtonList() }

    </div>;
  }
}

DropdownButton.propTypes = {
  list: PropTypes.arrayOf(PropTypes.shape({
    title: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired,
    target: PropTypes.string
  })),
  label: PropTypes.string.isRequired
};
