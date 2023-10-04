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

  const sendMessageRead = (msg) => {
    ApiUtil.patch(`/inbox/messages/${msg.id}`, { data: { message_action: 'read' } }).
      then(
        (response) => {
          const responseObject = JSON.parse(response.text);

          Object.assign(msg, responseObject);

          setMarkedRead({
            ...markedRead,
            [msg.id]: true
          });
        },
        (error) => {
          throw error;
        }
      ).
      catch((error) => error);
  };

  const markMessageRead = (msg) => {
    setMarkedRead({
      ...markedRead,
      [msg.id]: true
    });
    sendMessageRead(msg);
  };

  const formatDate = (datetime) => {
    return moment(datetime).format(DATE_TIME_FORMAT);
  };

  const getButtonText = (msg) => {
    let txt = 'Mark as read';

    if (msg.read_at) {
      txt = `Read ${formatDate(msg.read_at)}`;
    }

    return txt;
  };

  const markAsReadButtonDisabled = (msg) => {
    if (markedRead[msg.id] || msg.read_at) {
      return true;
    }

    return false;
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
    if (markedRead[msg.id] || msg.read_at) {
      return 'cf-inbox-message-read';
    }

    return 'cf-inbox-message';
  };

  const { messages } = props;

  return (
    <>
      {messages.length === 0 ? (
        <div className="cf-txt-c">
          <h1>Success! You have no unread messages.</h1>
        </div>
      ) : (
        <div className="cf-inbox-table">
          <h1>Inbox</h1>
          <hr />
          <div>
            Messages will remain in the intake box for 120 days. After such time, messages will be removed.
          </div>
          <Table columns={columns} rowObjects={messages} rowClassNames={rowClassNames} slowReRendersAreOk />
          <EasyPagination currentCases={messages.length} pagination={props.pagination} />
        </div>
      )}
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
