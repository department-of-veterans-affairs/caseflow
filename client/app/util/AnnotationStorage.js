import PDFJSAnnotate from 'pdf-annotate.js';
import ApiUtil from './ApiUtil';

export default class AnnotationStorage extends PDFJSAnnotate.StoreAdapter {
  getAnnotationByDocumentId = (documentId) => this.storedAnnotations[documentId] || []

  // TODO: What does this return if it's not found. Hopefully undefined.
  findAnnotation = (documentId, annotationId) => {
    let foundIndex = null;

    this.storedAnnotations[documentId].forEach((annotation, index) => {
      if (annotation.uuid.toString() === annotationId.toString()) {
        foundIndex = index;
      }
    });

    return foundIndex;
  }

  setOnCommentChange = (onCommentChange) => {
    this.onCommentChange = onCommentChange;
  }

  constructor(annotations) {
    super({
      addAnnotation: (documentId, pageNumber, annotation) =>
        new Promise((resolve, reject) => {
          annotation.class = 'Annotation';
          annotation.page = pageNumber;
          annotation.documentId = documentId;

          let allAnnotations = this.getAnnotationByDocumentId(documentId);

          allAnnotations.push(annotation);
          this.storedAnnotations[documentId] = allAnnotations;
          let data = ApiUtil.convertToSnakeCase({ annotation });

          ApiUtil.post(`/decision/review/annotation`, { data }).
              then((response) => {

                let responseObject = JSON.parse(response.text);

                annotation.uuid = responseObject.id;
                resolve(annotation);
                this.onCommentChange();
              }, () => {
                reject();
              });
        }),

      // We unified annotations and comments, so we will not implement this.
      addComment: () => new Promise((resolve) => {
        resolve([]);
      }),

      deleteAnnotation: (documentId, annotationId) => new Promise((resolve, reject) => {
        ApiUtil.delete(`/decision/review/annotation/${annotationId}`).
            then(() => {
              let index = this.findAnnotation(documentId, annotationId);

              if (index === null) {
                resolve(false);
              } else {
                let allAnnotations = this.storedAnnotations[documentId];

                allAnnotations.splice(index, 1);
                this.storedAnnotations[documentId] = allAnnotations;
                this.onCommentChange();
                resolve(true);
              }
            }, () => {
              reject();
            });
      }),

      // We unified annotations and comments, so we will not implement this.
      deleteComment: () => new Promise((resolve) => {
        resolve([]);
      }),

      editAnnotation: (documentId, annotationId, annotation) =>
        new Promise((resolve, reject) => {
          let index = this.findAnnotation(documentId, annotationId);

          if (index === null) {
            reject();
          }
          this.storedAnnotations[documentId][index] = annotation;

          let data = ApiUtil.convertToSnakeCase({ annotation });

          ApiUtil.patch(`/decision/review/annotation/${annotationId}`, { data }).
              then(() => {
                resolve(annotation);
                this.onCommentChange();
              }, () => {
                reject();
              });
        }),

      getAnnotation: (documentId, annotationId) => new Promise((resolve) => {
        let allAnnotations = this.getAnnotationByDocumentId(documentId);

        allAnnotations.forEach((annotation) => {
          if (annotation.uuid.toString() === annotationId.toString()) {
            resolve(annotation);
          }
        });
      }),

      getAnnotations: (documentId, pageNumber) => new Promise((resolve) => {
        let allAnnotations = this.getAnnotationByDocumentId(documentId);
        let pageAnnotations = allAnnotations.filter((i) => i.page === pageNumber);

        resolve({
          annotations: pageAnnotations,
          documentId,
          pageNumber });
      }),

      // We unified annotations and comments, so we will not implement this.
      getComments: () => new Promise((resolve) => {
        resolve([]);
      })
    });

    this.storedAnnotations = {};
    annotations.forEach((annotation) => {
      // We have to call it a uuid for the UI to properly use it
      annotation.uuid = annotation.id;
      annotation.class = "annotation";
      annotation.type = "point";
      annotation.documentId = annotation.document_id;

      if (!this.storedAnnotations[annotation.documentId]) {
        this.storedAnnotations[annotation.documentId] = [];
      }
      this.storedAnnotations[annotation.documentId].push(annotation);
    });

    this.onCommentChange = () => {
      // do nothing
    };
  }
}


