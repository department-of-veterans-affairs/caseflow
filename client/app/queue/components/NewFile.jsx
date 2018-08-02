// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { NewFileIcon } from '../../components/RenderFunctions';
import { bindActionCreators } from 'redux';
import { getNewDocuments } from '../QueueActions';
import type {
  BasicAppeal
} from '../types/models';

type Params = {|
  appeal: BasicAppeal
|};

type Props = Params & {|
  docs: Array<Object>,
  error: string,
  getNewDocuments: Function
|};

class NewFile extends React.Component<Props> {
  componentDidMount = () => {
    if (!this.props.docs) {
      this.props.getNewDocuments(this.props.appeal.externalId);
    }
  }

  render = () => {
    if (this.props.docs && this.props.docs.length > 0) {
      return <NewFileIcon />;
    }

    return null;

  }
}

const mapStateToProps = (state, ownProps) => {
  const documentObject = state.queue.newDocsForAppeal[ownProps.appeal.externalId];

  return {
    docs: documentObject ? documentObject.docs : null,
    error: documentObject ? documentObject.error : null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getNewDocuments
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(NewFile): React.ComponentType<Params>);
