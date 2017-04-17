import React, { PropTypes } from 'react';
import IconButton from '../components/IconButton';

class DropdownFilter extends React.PureComponent {
  constructor() {
    super();
    this.state = {
      rootElemWidth: null
    };
  }
  render() {
    const { children, baseCoordinates } = this.props;

    if (!baseCoordinates) {
      return null;
    }

    let style;

    if (this.state.rootElemWidth) {
      const offset = {
        top: 5
      };

      style = {
        top: baseCoordinates.bottom + offset.top,
        left: baseCoordinates.right - this.state.rootElemWidth
      };
    } else {
      style = { left: '-99999px' };
    }

    return <div className="cf-dropdown-filter" style={style} ref={(rootElem) => {
      this.rootElem = rootElem;
    }}>
      <div>
        Clear category filter{' '}
          <IconButton iconName="fa-times" handleActivate={this.props.handleClose} />
      </div>
      {children}
    </div>;
  }

  componentDidMount() {
    if (this.rootElem) {
      this.setState({
        rootElemWidth: this.rootElem.clientWidth
      });
    }
  }
}

export default DropdownFilter;
