/* eslint-disable react/prop-types */
import React from 'react';
import { connect } from 'react-redux';
import moment from 'moment';

import Button from '../../components/Button';
import Table from '../../components/Table';
import Pagination from '../../components/Pagination';

import ApiUtil from '../../util/ApiUtil';

const DATE_TIME_FORMAT = 'ddd MMM DD HH:mm:ss YYYY';

class InboxMessagesPage extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      markedRead: {}
    };
  }

  markMessageRead = (msg) => {
    let markedRead = { ...this.state.markedRead };

    markedRead[msg.id] = true;
    this.setState({ markedRead });
    this.sendMessageRead(msg);
  }

  sendMessageRead = (msg) => {
    let page = this;

    ApiUtil.patch(`/inbox/messages/${msg.id}`, { data: { message_action: "read" } }).
      then(
        (response) => {
          const responseObject = JSON.parse(response.text);

          Object.assign(msg, responseObject);

          let markedRead = { ...page.state.markedRead };

          markedRead[msg.id] = true;
          page.setState({
            markedRead
          });
        },
        (error) => {
          throw error;
        }
      ).
      catch((error) => error);
  }

  getButtonText = (msg) => {
    let txt = 'Mark as read';

    if (msg.read_at) {
      txt = "Read " + this.formatDate(msg.read_at);
    }

    return txt;
  }

  formatDate = (datetime) => {
    return moment(datetime).format(DATE_TIME_FORMAT);
  }

  markAsReadButtonDisabled = (msg) => {
    if (this.state.markedRead[msg.id] || msg.read_at) {
      return true;
    }

    return false;
  }

  render = () => {
    const rowObjects = this.props.messages;

    if (rowObjects.length === 0) {
      return <div>
        <h1>Success! You have no unread messages.</h1>
      </div>;
    }

    const columns = [
      {
        header: 'Date',
        valueFunction: (msg) => {
          return this.formatDate(msg.created_at);
        }
      },
      {
        header: 'Message',
        valueFunction: (msg) => {
          // allow raw html since we control message content.
          return <span className="cf-inbox-message" dangerouslySetInnerHTML={{ __html: msg.text}} />;
        }
      },
      {
        align: 'right',
        valueFunction: (msg) => {
          return <Button
            id={`inbox-message-${msg.id}`}
            title={`message ${msg.id}`}
            disabled={this.markAsReadButtonDisabled(msg)}
            onClick={() => {
              this.markMessageRead(msg);
            }}
          >{this.getButtonText(msg)}</Button>;
        }
      }
    ];

    const rowClassNames = (msg) => {
      if (this.state.markedRead[msg.id] || msg.read_at) {
        return 'cf-inbox-message-read';
      }

      return 'cf-inbox-message';
    };

    const pageUpdater = (idx) => {
      let newPage = idx + 1;

      if (newPage !== this.props.pagination.current_page) {
        let newUrl = `${window.location.href.split('?')[0]}?page=${newPage}`;

        window.location = newUrl;
      }
    };

    return <div className="cf-inbox-table">
      <h1>Inbox</h1>
      <hr />
      <Table columns={columns} rowObjects={rowObjects} rowClassNames={rowClassNames} slowReRendersAreOk />
      <Pagination
        currentPage={this.props.pagination.current_page}
        currentCases={rowObjects.length}
        totalCases={this.props.pagination.total_messages}
        totalPages={this.props.pagination.total_pages}
        pageSize={this.props.pagination.page_size}
        updatePage={pageUpdater} />
    </div>;
  }
}

const InboxPage = connect(
  (state) => ({
    messages: state.messages,
    pagination: state.pagination
  })
)(InboxMessagesPage);

export default InboxPage;
