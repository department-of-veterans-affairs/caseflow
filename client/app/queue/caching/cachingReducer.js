import { combineReducers } from '@reduxjs/toolkit';
import queueTableCacheReducer from './queueTableCache.slice';

const cachingReducer = combineReducers({
  queueTable: queueTableCacheReducer,
});

export default cachingReducer;
