import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';
import Button from './Button';

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
    document.addEventListener('keydown', this.onClickOutside);
    document.addEventListener('mousedown', this.onClickOutside);
  }

  componentWillUnmount = () => {
    document.removeEventListener('keydown', this.onClickOutside);
    document.removeEventListener('mousedown', this.onClickOutside);
  }
  setWrapperRef = (node) => this.wrapperRef = node

  onClickOutside = (event) => {
    // event.composedPath() is [html, document, Window] when clicking the scroll bar and more when clicking content
    // this stops the menu from closing if a user clicks to use the scroll bar with the menu open
    if (this.wrapperRef && !this.wrapperRef.contains(event.target) &&
     event.composedPath()[2] !== window && this.state.menu) {
      this.setState({
        menu: false
      });
    } else if (event.key === 'Escape') {
      this.setState({
        menu: false
      });
      event.preventDefault();
    }
  }

  onMenuClick = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  dropdownLink = (list) => {
    return <Link className="usa-button-secondary usa-button"
      href={list.target}>{list.title}</Link>;
  }

  /**
   * TODO This should be merged with or replaced by dropdownLink
   * @param list
   * @return {JSX.Element}
   */
  dropdownAction = (list) => {
    return <a href={`#${list.value}`} onClick={() => {
      if (this.props.onClick) {
        this.props.onClick(list.value);
      }
      this.onMenuClick();
    }}>{list.title}</a>;
  }

  dropdownButton = (list) => {
    return <Button classNames={['cf-btn-link']}
      onClick={() => {
        if (this.props.onClick) {
          this.props.onClick(list.value);
        }
        this.onMenuClick();
      }}>
      {list.title}
    </Button>;
  }

  renderLiBody = (list) => {
    if (list.button) {
      return this.dropdownButton(list);
    }

    return list.target ? this.dropdownLink(list) : this.dropdownAction(list);
  }
  dropdownButtonList = () => {
    return <ul role="listbox" className="cf-dropdown-menu active" {...dropdownList}>
      {this.props.lists.map((list, index) =>
        <li role="option" key={index}>
          {this.renderLiBody(list)}
        </li>)}
    </ul>;
  };

  render() {
    const { label, children } = this.props;

    return <div className="cf-dropdown" ref={this.setWrapperRef} {...dropdownBtnContainer} >
      <button {...dropdownBtn}
        role="button"
        aria-label={label || 'dropdown-button'}
        aria-haspopup="listbox"
        aria-expanded={this.state.menu}
        aria-pressed={this.state.menu}
        onClick={this.onMenuClick}
        className="cf-dropdown-trigger usa-button usa-button-secondary">
        {children || label}
      </button>
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
  label: PropTypes.string.isRequired,
  lists: PropTypes.array.isRequired,
  children: PropTypes.node,
};
