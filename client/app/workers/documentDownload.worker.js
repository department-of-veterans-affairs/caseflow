import ApiUtil from '../util/ApiUtil';

const PARALLEL_THREADS = 3;

function downloadDocuments(documents, index) {
  if (index < documents.length) {
    console.log(documents[index]);
    ApiUtil.get(documents[index])
      .then(() => {
        downloadDocuments(documents, index + PARALLEL_THREADS);
      });
  }
}

self.addEventListener('message', (event) => {
  for (let i = 0; i < PARALLEL_THREADS; i++){
    downloadDocuments(event.data, i);
  }
})
