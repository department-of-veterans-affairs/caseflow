import React, { useState } from 'react';
import { connect } from 'react-redux';
import moment from 'moment';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import Table from '../../components/Table';
import EasyPagination from '../../components/Pagination/EasyPagination';

import ApiUtil from '../../util/ApiUtil';

const DATE_TIME_FORMAT = 'ddd MMM DD YYYY [at] HH:mm';

export const InboxMessagesPage = (props) => {
  const [markedRead, setMarkedRead] = useState({});

  const markMessageRead = (msg) => {
    const markedRead = { ...this.state.markedRead };

    markedRead[msg.id] = true;
    this.setState({ markedRead });
    this.sendMessageRead(msg);
  };

  const sendMessageRead = (msg) => {
    const page = this;

    ApiUtil.patch(`/inbox/messages/${msg.id}`, { data: { message_action: 'read' } }).
      then(
        (response) => {
          const responseObject = JSON.parse(response.text);

          Object.assign(msg, responseObject);

          const markedRead = { ...page.state.markedRead };

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
  };

  const getButtonText = (msg) => {
    let txt = 'Mark as read';

    if (msg.read_at) {
      txt = `Read ${this.formatDate(msg.read_at)}`;
    }

    return txt;
  };

  const formatDate = (datetime) => {
    return moment(datetime).format(DATE_TIME_FORMAT);
  };

  const markAsReadButtonDisabled = (msg) => {
    if (this.state.markedRead[msg.id] || msg.read_at) {
      return true;
    }

    return false;
  };

  const rowObjects = props.messages;

  const inboxIsEmpty = () => {
    if (rowObjects.length === 0) {
      return <div>
        <h1>Success! You have no unread messages.</h1>
      </div>;
    }
  };

  const columns = [
    {
      header: 'Received',
      valueFunction: (msg) => {
        return formatDate(msg.created_at);
      }
    },
    {
      header: 'Message',
      valueFunction: (msg) => {
        // allow raw html since we control message content.
        return <span className="cf-inbox-message" dangerouslySetInnerHTML={{ __html: msg.text }} />;
      }
    },
    {
      align: 'right',
      valueFunction: (msg) => {
        return <Button
          id={`inbox-message-${msg.id}`}
          title={`message ${msg.id}`}
          disabled={markAsReadButtonDisabled(msg)}
          onClick={() => {
            markMessageRead(msg);
          }}
        >{getButtonText(msg)}</Button>;
      }
    }
  ];

  const rowClassNames = (msg) => {
    if (this.state.markedRead[msg.id] || msg.read_at) {
      return 'cf-inbox-message-read';
    }

    return 'cf-inbox-message';
  };

  return (
    <>
      {inboxIsEmpty}
      {columns}
      {rowClassNames}
      <div className="cf-inbox-table">
        <h1>Inbox</h1>
        <hr />
        <div>
          Messages will remain in the intake box for 120 days. After such time, messages will be removed.
        </div>
        <Table columns={columns} rowObjects={rowObjects} rowClassNames={rowClassNames} slowReRendersAreOk />
        <EasyPagination currentCases={rowObjects.length} pagination={props.pagination} />
      </div>;
    </>
  );
};

InboxMessagesPage.propTypes = {
  messages: PropTypes.arrayOf(PropTypes.object).isRequired,
  pagination: PropTypes.object.isRequired,
};

const InboxPage = connect(
  (state) => ({
    messages: state.messages,
    pagination: state.pagination
  })
)(InboxMessagesPage);

export default InboxPage;
