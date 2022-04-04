/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/*
 * This file was created by apiwrap.rb.
 * Don't edit this file manually.
 */
#ifndef APIWRAP_H
#define APIWRAP_H 1
#include <oci8.h>

#if defined RUNTIME_API_CHECK
void Init_oci8_apiwrap(void);
extern int oracle_client_version;
#else
#define oracle_client_version ORACLE_CLIENT_VERSION
#endif

/*
 * OCIAttrGet
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIAttrGet(CONST dvoid *trgthndlp, ub4 trghndltyp, dvoid *attributep, ub4 *sizep, ub4 attrtype, OCIError *errhp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIAttrGet
#define OCIAttrGet(trgthndlp, trghndltyp, attributep, sizep, attrtype, errhp) \
      oci8_OCIAttrGet(trgthndlp, trghndltyp, attributep, sizep, attrtype, errhp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIAttrGet;
#define have_OCIAttrGet oci8_have_OCIAttrGet
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIAttrGet (1)
#else
#define have_OCIAttrGet (0)
#endif

/*
 * OCIAttrGet
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCIAttrGet_nb(oci8_svcctx_t *svcctx, CONST dvoid *trgthndlp, ub4 trghndltyp, dvoid *attributep, ub4 *sizep, ub4 attrtype, OCIError *errhp, const char *file, int line);
#define OCIAttrGet_nb(svcctx, trgthndlp, trghndltyp, attributep, sizep, attrtype, errhp) \
      oci8_OCIAttrGet_nb(svcctx, trgthndlp, trghndltyp, attributep, sizep, attrtype, errhp, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIAttrGet_nb;
#define have_OCIAttrGet_nb oci8_have_OCIAttrGet_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIAttrGet_nb (1)
#else
#define have_OCIAttrGet_nb (0)
#endif

/*
 * OCIAttrSet
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIAttrSet(dvoid *trgthndlp, ub4 trghndltyp, dvoid *attributep, ub4 size, ub4 attrtype, OCIError *errhp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIAttrSet
#define OCIAttrSet(trgthndlp, trghndltyp, attributep, size, attrtype, errhp) \
      oci8_OCIAttrSet(trgthndlp, trghndltyp, attributep, size, attrtype, errhp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIAttrSet;
#define have_OCIAttrSet oci8_have_OCIAttrSet
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIAttrSet (1)
#else
#define have_OCIAttrSet (0)
#endif

/*
 * OCIBindArrayOfStruct
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIBindArrayOfStruct(OCIBind *bindp, OCIError *errhp, ub4 pvskip, ub4 indskip, ub4 alskip, ub4 rcskip, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIBindArrayOfStruct
#define OCIBindArrayOfStruct(bindp, errhp, pvskip, indskip, alskip, rcskip) \
      oci8_OCIBindArrayOfStruct(bindp, errhp, pvskip, indskip, alskip, rcskip, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIBindArrayOfStruct;
#define have_OCIBindArrayOfStruct oci8_have_OCIBindArrayOfStruct
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIBindArrayOfStruct (1)
#else
#define have_OCIBindArrayOfStruct (0)
#endif

/*
 * OCIBindByName
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIBindByName(OCIStmt *stmtp, OCIBind **bindp, OCIError *errhp, CONST text *placeholder, sb4 placeh_len, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *alenp, ub2 *rcodep, ub4 maxarr_len, ub4 *curelep, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIBindByName
#define OCIBindByName(stmtp, bindp, errhp, placeholder, placeh_len, valuep, value_sz, dty, indp, alenp, rcodep, maxarr_len, curelep, mode) \
      oci8_OCIBindByName(stmtp, bindp, errhp, placeholder, placeh_len, valuep, value_sz, dty, indp, alenp, rcodep, maxarr_len, curelep, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIBindByName;
#define have_OCIBindByName oci8_have_OCIBindByName
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIBindByName (1)
#else
#define have_OCIBindByName (0)
#endif

/*
 * OCIBindByPos
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIBindByPos(OCIStmt *stmtp, OCIBind **bindp, OCIError *errhp, ub4 position, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *alenp, ub2 *rcodep, ub4 maxarr_len, ub4 *curelep, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIBindByPos
#define OCIBindByPos(stmtp, bindp, errhp, position, valuep, value_sz, dty, indp, alenp, rcodep, maxarr_len, curelep, mode) \
      oci8_OCIBindByPos(stmtp, bindp, errhp, position, valuep, value_sz, dty, indp, alenp, rcodep, maxarr_len, curelep, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIBindByPos;
#define have_OCIBindByPos oci8_have_OCIBindByPos
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIBindByPos (1)
#else
#define have_OCIBindByPos (0)
#endif

/*
 * OCIBindDynamic
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIBindDynamic(OCIBind *bindp, OCIError *errhp, void  *ictxp, OCICallbackInBind icbfp, void  *octxp, OCICallbackOutBind ocbfp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIBindDynamic
#define OCIBindDynamic(bindp, errhp, ictxp, icbfp, octxp, ocbfp) \
      oci8_OCIBindDynamic(bindp, errhp, ictxp, icbfp, octxp, ocbfp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIBindDynamic;
#define have_OCIBindDynamic oci8_have_OCIBindDynamic
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIBindDynamic (1)
#else
#define have_OCIBindDynamic (0)
#endif

/*
 * OCIBindObject
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIBindObject(OCIBind *bindp, OCIError *errhp, CONST OCIType *type, dvoid **pgvpp, ub4 *pvszsp, dvoid **indpp, ub4 *indszp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIBindObject
#define OCIBindObject(bindp, errhp, type, pgvpp, pvszsp, indpp, indszp) \
      oci8_OCIBindObject(bindp, errhp, type, pgvpp, pvszsp, indpp, indszp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIBindObject;
#define have_OCIBindObject oci8_have_OCIBindObject
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIBindObject (1)
#else
#define have_OCIBindObject (0)
#endif

/*
 * OCIBreak
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIBreak(dvoid *hndlp, OCIError *errhp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIBreak
#define OCIBreak(hndlp, errhp) \
      oci8_OCIBreak(hndlp, errhp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIBreak;
#define have_OCIBreak oci8_have_OCIBreak
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIBreak (1)
#else
#define have_OCIBreak (0)
#endif

/*
 * OCICollAppend
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCICollAppend(OCIEnv *env, OCIError *err, CONST dvoid *elem, CONST dvoid *elemind, OCIColl *coll, const char *file, int line);
#ifndef API_WRAP_C
#undef OCICollAppend
#define OCICollAppend(env, err, elem, elemind, coll) \
      oci8_OCICollAppend(env, err, elem, elemind, coll, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCICollAppend;
#define have_OCICollAppend oci8_have_OCICollAppend
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCICollAppend (1)
#else
#define have_OCICollAppend (0)
#endif

/*
 * OCICollAssignElem
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCICollAssignElem(OCIEnv *env, OCIError *err, sb4 index, CONST dvoid *elem, CONST dvoid *elemind, OCIColl *coll, const char *file, int line);
#ifndef API_WRAP_C
#undef OCICollAssignElem
#define OCICollAssignElem(env, err, index, elem, elemind, coll) \
      oci8_OCICollAssignElem(env, err, index, elem, elemind, coll, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCICollAssignElem;
#define have_OCICollAssignElem oci8_have_OCICollAssignElem
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCICollAssignElem (1)
#else
#define have_OCICollAssignElem (0)
#endif

/*
 * OCICollGetElem
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCICollGetElem(OCIEnv *env, OCIError *err, CONST OCIColl *coll, sb4 index, boolean *exists, dvoid **elem, dvoid **elemind, const char *file, int line);
#ifndef API_WRAP_C
#undef OCICollGetElem
#define OCICollGetElem(env, err, coll, index, exists, elem, elemind) \
      oci8_OCICollGetElem(env, err, coll, index, exists, elem, elemind, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCICollGetElem;
#define have_OCICollGetElem oci8_have_OCICollGetElem
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCICollGetElem (1)
#else
#define have_OCICollGetElem (0)
#endif

/*
 * OCICollSize
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCICollSize(OCIEnv *env, OCIError *err, CONST OCIColl *coll, sb4 *size, const char *file, int line);
#ifndef API_WRAP_C
#undef OCICollSize
#define OCICollSize(env, err, coll, size) \
      oci8_OCICollSize(env, err, coll, size, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCICollSize;
#define have_OCICollSize oci8_have_OCICollSize
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCICollSize (1)
#else
#define have_OCICollSize (0)
#endif

/*
 * OCICollTrim
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCICollTrim(OCIEnv *env, OCIError *err, sb4 trim_num, OCIColl *coll, const char *file, int line);
#ifndef API_WRAP_C
#undef OCICollTrim
#define OCICollTrim(env, err, trim_num, coll) \
      oci8_OCICollTrim(env, err, trim_num, coll, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCICollTrim;
#define have_OCICollTrim oci8_have_OCICollTrim
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCICollTrim (1)
#else
#define have_OCICollTrim (0)
#endif

/*
 * OCIDefineArrayOfStruct
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIDefineArrayOfStruct(OCIDefine *defnp, OCIError *errhp, ub4 pvskip, ub4 indskip, ub4 rlskip, ub4 rcskip, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDefineArrayOfStruct
#define OCIDefineArrayOfStruct(defnp, errhp, pvskip, indskip, rlskip, rcskip) \
      oci8_OCIDefineArrayOfStruct(defnp, errhp, pvskip, indskip, rlskip, rcskip, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDefineArrayOfStruct;
#define have_OCIDefineArrayOfStruct oci8_have_OCIDefineArrayOfStruct
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIDefineArrayOfStruct (1)
#else
#define have_OCIDefineArrayOfStruct (0)
#endif

/*
 * OCIDefineByPos
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIDefineByPos(OCIStmt *stmtp, OCIDefine **defnp, OCIError *errhp, ub4 position, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *rlenp, ub2 *rcodep, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDefineByPos
#define OCIDefineByPos(stmtp, defnp, errhp, position, valuep, value_sz, dty, indp, rlenp, rcodep, mode) \
      oci8_OCIDefineByPos(stmtp, defnp, errhp, position, valuep, value_sz, dty, indp, rlenp, rcodep, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDefineByPos;
#define have_OCIDefineByPos oci8_have_OCIDefineByPos
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIDefineByPos (1)
#else
#define have_OCIDefineByPos (0)
#endif

/*
 * OCIDefineDynamic
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIDefineDynamic(OCIDefine *defnp, OCIError *errhp, dvoid *octxp, OCICallbackDefine ocbfp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDefineDynamic
#define OCIDefineDynamic(defnp, errhp, octxp, ocbfp) \
      oci8_OCIDefineDynamic(defnp, errhp, octxp, ocbfp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDefineDynamic;
#define have_OCIDefineDynamic oci8_have_OCIDefineDynamic
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIDefineDynamic (1)
#else
#define have_OCIDefineDynamic (0)
#endif

/*
 * OCIDefineObject
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIDefineObject(OCIDefine *defnp, OCIError *errhp, CONST OCIType *type, dvoid **pgvpp, ub4 *pvszsp, dvoid **indpp, ub4 *indszp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDefineObject
#define OCIDefineObject(defnp, errhp, type, pgvpp, pvszsp, indpp, indszp) \
      oci8_OCIDefineObject(defnp, errhp, type, pgvpp, pvszsp, indpp, indszp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDefineObject;
#define have_OCIDefineObject oci8_have_OCIDefineObject
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIDefineObject (1)
#else
#define have_OCIDefineObject (0)
#endif

/*
 * OCIDescribeAny
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCIDescribeAny_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, dvoid *objptr, ub4 objnm_len, ub1 objptr_typ, ub1 info_level, ub1 objtyp, OCIDescribe *dschp, const char *file, int line);
#define OCIDescribeAny_nb(svcctx, svchp, errhp, objptr, objnm_len, objptr_typ, info_level, objtyp, dschp) \
      oci8_OCIDescribeAny_nb(svcctx, svchp, errhp, objptr, objnm_len, objptr_typ, info_level, objtyp, dschp, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDescribeAny_nb;
#define have_OCIDescribeAny_nb oci8_have_OCIDescribeAny_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIDescribeAny_nb (1)
#else
#define have_OCIDescribeAny_nb (0)
#endif

/*
 * OCIDescriptorAlloc
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIDescriptorAlloc(CONST dvoid *parenth, dvoid **descpp, ub4 type, size_t xtramem_sz, dvoid **usrmempp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDescriptorAlloc
#define OCIDescriptorAlloc(parenth, descpp, type, xtramem_sz, usrmempp) \
      oci8_OCIDescriptorAlloc(parenth, descpp, type, xtramem_sz, usrmempp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDescriptorAlloc;
#define have_OCIDescriptorAlloc oci8_have_OCIDescriptorAlloc
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIDescriptorAlloc (1)
#else
#define have_OCIDescriptorAlloc (0)
#endif

/*
 * OCIDescriptorFree
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIDescriptorFree(dvoid *descp, ub4 type, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDescriptorFree
#define OCIDescriptorFree(descp, type) \
      oci8_OCIDescriptorFree(descp, type, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDescriptorFree;
#define have_OCIDescriptorFree oci8_have_OCIDescriptorFree
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIDescriptorFree (1)
#else
#define have_OCIDescriptorFree (0)
#endif

/*
 * OCIErrorGet
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIErrorGet(dvoid *hndlp, ub4 recordno, text *sqlstate, sb4 *errcodep, text *bufp, ub4 bufsiz, ub4 type, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIErrorGet
#define OCIErrorGet(hndlp, recordno, sqlstate, errcodep, bufp, bufsiz, type) \
      oci8_OCIErrorGet(hndlp, recordno, sqlstate, errcodep, bufp, bufsiz, type, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIErrorGet;
#define have_OCIErrorGet oci8_have_OCIErrorGet
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIErrorGet (1)
#else
#define have_OCIErrorGet (0)
#endif

/*
 * OCIHandleAlloc
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIHandleAlloc(CONST dvoid *parenth, dvoid **hndlpp, ub4 type, size_t xtramem_sz, dvoid **usrmempp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIHandleAlloc
#define OCIHandleAlloc(parenth, hndlpp, type, xtramem_sz, usrmempp) \
      oci8_OCIHandleAlloc(parenth, hndlpp, type, xtramem_sz, usrmempp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIHandleAlloc;
#define have_OCIHandleAlloc oci8_have_OCIHandleAlloc
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIHandleAlloc (1)
#else
#define have_OCIHandleAlloc (0)
#endif

/*
 * OCIHandleFree
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIHandleFree(dvoid *hndlp, ub4 type, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIHandleFree
#define OCIHandleFree(hndlp, type) \
      oci8_OCIHandleFree(hndlp, type, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIHandleFree;
#define have_OCIHandleFree oci8_have_OCIHandleFree
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIHandleFree (1)
#else
#define have_OCIHandleFree (0)
#endif

/*
 * OCILobAssign
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCILobAssign(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *src_locp, OCILobLocator **dst_locpp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCILobAssign
#define OCILobAssign(envhp, errhp, src_locp, dst_locpp) \
      oci8_OCILobAssign(envhp, errhp, src_locp, dst_locpp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobAssign;
#define have_OCILobAssign oci8_have_OCILobAssign
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCILobAssign (1)
#else
#define have_OCILobAssign (0)
#endif

/*
 * OCILobFileClose
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCILobFileClose_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep, const char *file, int line);
#define OCILobFileClose_nb(svcctx, svchp, errhp, filep) \
      oci8_OCILobFileClose_nb(svcctx, svchp, errhp, filep, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobFileClose_nb;
#define have_OCILobFileClose_nb oci8_have_OCILobFileClose_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCILobFileClose_nb (1)
#else
#define have_OCILobFileClose_nb (0)
#endif

/*
 * OCILobFileCloseAll
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCILobFileCloseAll_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, const char *file, int line);
#define OCILobFileCloseAll_nb(svcctx, svchp, errhp) \
      oci8_OCILobFileCloseAll_nb(svcctx, svchp, errhp, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobFileCloseAll_nb;
#define have_OCILobFileCloseAll_nb oci8_have_OCILobFileCloseAll_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCILobFileCloseAll_nb (1)
#else
#define have_OCILobFileCloseAll_nb (0)
#endif

/*
 * OCILobFileExists
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCILobFileExists_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep, boolean *flag, const char *file, int line);
#define OCILobFileExists_nb(svcctx, svchp, errhp, filep, flag) \
      oci8_OCILobFileExists_nb(svcctx, svchp, errhp, filep, flag, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobFileExists_nb;
#define have_OCILobFileExists_nb oci8_have_OCILobFileExists_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCILobFileExists_nb (1)
#else
#define have_OCILobFileExists_nb (0)
#endif

/*
 * OCILobFileGetName
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCILobFileGetName(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *filep, text *dir_alias, ub2 *d_length, text *filename, ub2 *f_length, const char *file, int line);
#ifndef API_WRAP_C
#undef OCILobFileGetName
#define OCILobFileGetName(envhp, errhp, filep, dir_alias, d_length, filename, f_length) \
      oci8_OCILobFileGetName(envhp, errhp, filep, dir_alias, d_length, filename, f_length, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobFileGetName;
#define have_OCILobFileGetName oci8_have_OCILobFileGetName
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCILobFileGetName (1)
#else
#define have_OCILobFileGetName (0)
#endif

/*
 * OCILobFileOpen
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCILobFileOpen_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep, ub1 mode, const char *file, int line);
#define OCILobFileOpen_nb(svcctx, svchp, errhp, filep, mode) \
      oci8_OCILobFileOpen_nb(svcctx, svchp, errhp, filep, mode, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobFileOpen_nb;
#define have_OCILobFileOpen_nb oci8_have_OCILobFileOpen_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCILobFileOpen_nb (1)
#else
#define have_OCILobFileOpen_nb (0)
#endif

/*
 * OCILobFileSetName
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCILobFileSetName(OCIEnv *envhp, OCIError *errhp, OCILobLocator **filepp, CONST text *dir_alias, ub2 d_length, CONST text *filename, ub2 f_length, const char *file, int line);
#ifndef API_WRAP_C
#undef OCILobFileSetName
#define OCILobFileSetName(envhp, errhp, filepp, dir_alias, d_length, filename, f_length) \
      oci8_OCILobFileSetName(envhp, errhp, filepp, dir_alias, d_length, filename, f_length, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobFileSetName;
#define have_OCILobFileSetName oci8_have_OCILobFileSetName
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCILobFileSetName (1)
#else
#define have_OCILobFileSetName (0)
#endif

/*
 * OCILobLocatorIsInit
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCILobLocatorIsInit(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *locp, boolean *is_initialized, const char *file, int line);
#ifndef API_WRAP_C
#undef OCILobLocatorIsInit
#define OCILobLocatorIsInit(envhp, errhp, locp, is_initialized) \
      oci8_OCILobLocatorIsInit(envhp, errhp, locp, is_initialized, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobLocatorIsInit;
#define have_OCILobLocatorIsInit oci8_have_OCILobLocatorIsInit
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCILobLocatorIsInit (1)
#else
#define have_OCILobLocatorIsInit (0)
#endif

/*
 * OCINumberAbs
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberAbs(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberAbs
#define OCINumberAbs(err, number, result) \
      oci8_OCINumberAbs(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberAbs;
#define have_OCINumberAbs oci8_have_OCINumberAbs
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberAbs (1)
#else
#define have_OCINumberAbs (0)
#endif

/*
 * OCINumberAdd
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberAdd(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberAdd
#define OCINumberAdd(err, number1, number2, result) \
      oci8_OCINumberAdd(err, number1, number2, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberAdd;
#define have_OCINumberAdd oci8_have_OCINumberAdd
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberAdd (1)
#else
#define have_OCINumberAdd (0)
#endif

/*
 * OCINumberArcCos
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberArcCos(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberArcCos
#define OCINumberArcCos(err, number, result) \
      oci8_OCINumberArcCos(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberArcCos;
#define have_OCINumberArcCos oci8_have_OCINumberArcCos
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberArcCos (1)
#else
#define have_OCINumberArcCos (0)
#endif

/*
 * OCINumberArcSin
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberArcSin(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberArcSin
#define OCINumberArcSin(err, number, result) \
      oci8_OCINumberArcSin(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberArcSin;
#define have_OCINumberArcSin oci8_have_OCINumberArcSin
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberArcSin (1)
#else
#define have_OCINumberArcSin (0)
#endif

/*
 * OCINumberArcTan
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberArcTan(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberArcTan
#define OCINumberArcTan(err, number, result) \
      oci8_OCINumberArcTan(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberArcTan;
#define have_OCINumberArcTan oci8_have_OCINumberArcTan
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberArcTan (1)
#else
#define have_OCINumberArcTan (0)
#endif

/*
 * OCINumberArcTan2
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberArcTan2(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberArcTan2
#define OCINumberArcTan2(err, number1, number2, result) \
      oci8_OCINumberArcTan2(err, number1, number2, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberArcTan2;
#define have_OCINumberArcTan2 oci8_have_OCINumberArcTan2
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberArcTan2 (1)
#else
#define have_OCINumberArcTan2 (0)
#endif

/*
 * OCINumberAssign
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberAssign(OCIError *err, CONST OCINumber *from, OCINumber *to, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberAssign
#define OCINumberAssign(err, from, to) \
      oci8_OCINumberAssign(err, from, to, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberAssign;
#define have_OCINumberAssign oci8_have_OCINumberAssign
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberAssign (1)
#else
#define have_OCINumberAssign (0)
#endif

/*
 * OCINumberCeil
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberCeil(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberCeil
#define OCINumberCeil(err, number, result) \
      oci8_OCINumberCeil(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberCeil;
#define have_OCINumberCeil oci8_have_OCINumberCeil
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberCeil (1)
#else
#define have_OCINumberCeil (0)
#endif

/*
 * OCINumberCmp
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberCmp(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, sword *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberCmp
#define OCINumberCmp(err, number1, number2, result) \
      oci8_OCINumberCmp(err, number1, number2, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberCmp;
#define have_OCINumberCmp oci8_have_OCINumberCmp
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberCmp (1)
#else
#define have_OCINumberCmp (0)
#endif

/*
 * OCINumberCos
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberCos(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberCos
#define OCINumberCos(err, number, result) \
      oci8_OCINumberCos(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberCos;
#define have_OCINumberCos oci8_have_OCINumberCos
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberCos (1)
#else
#define have_OCINumberCos (0)
#endif

/*
 * OCINumberDiv
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberDiv(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberDiv
#define OCINumberDiv(err, number1, number2, result) \
      oci8_OCINumberDiv(err, number1, number2, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberDiv;
#define have_OCINumberDiv oci8_have_OCINumberDiv
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberDiv (1)
#else
#define have_OCINumberDiv (0)
#endif

/*
 * OCINumberExp
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberExp(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberExp
#define OCINumberExp(err, number, result) \
      oci8_OCINumberExp(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberExp;
#define have_OCINumberExp oci8_have_OCINumberExp
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberExp (1)
#else
#define have_OCINumberExp (0)
#endif

/*
 * OCINumberFloor
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberFloor(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberFloor
#define OCINumberFloor(err, number, result) \
      oci8_OCINumberFloor(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberFloor;
#define have_OCINumberFloor oci8_have_OCINumberFloor
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberFloor (1)
#else
#define have_OCINumberFloor (0)
#endif

/*
 * OCINumberFromInt
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberFromInt(OCIError *err, CONST dvoid *inum, uword inum_length, uword inum_s_flag, OCINumber *number, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberFromInt
#define OCINumberFromInt(err, inum, inum_length, inum_s_flag, number) \
      oci8_OCINumberFromInt(err, inum, inum_length, inum_s_flag, number, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberFromInt;
#define have_OCINumberFromInt oci8_have_OCINumberFromInt
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberFromInt (1)
#else
#define have_OCINumberFromInt (0)
#endif

/*
 * OCINumberFromReal
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberFromReal(OCIError *err, CONST dvoid *rnum, uword rnum_length, OCINumber *number, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberFromReal
#define OCINumberFromReal(err, rnum, rnum_length, number) \
      oci8_OCINumberFromReal(err, rnum, rnum_length, number, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberFromReal;
#define have_OCINumberFromReal oci8_have_OCINumberFromReal
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberFromReal (1)
#else
#define have_OCINumberFromReal (0)
#endif

/*
 * OCINumberFromText
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberFromText(OCIError *err, CONST text *str, ub4 str_length, CONST text *fmt, ub4 fmt_length, CONST text *nls_params, ub4 nls_p_length, OCINumber *number, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberFromText
#define OCINumberFromText(err, str, str_length, fmt, fmt_length, nls_params, nls_p_length, number) \
      oci8_OCINumberFromText(err, str, str_length, fmt, fmt_length, nls_params, nls_p_length, number, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberFromText;
#define have_OCINumberFromText oci8_have_OCINumberFromText
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberFromText (1)
#else
#define have_OCINumberFromText (0)
#endif

/*
 * OCINumberHypCos
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberHypCos(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberHypCos
#define OCINumberHypCos(err, number, result) \
      oci8_OCINumberHypCos(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberHypCos;
#define have_OCINumberHypCos oci8_have_OCINumberHypCos
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberHypCos (1)
#else
#define have_OCINumberHypCos (0)
#endif

/*
 * OCINumberHypSin
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberHypSin(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberHypSin
#define OCINumberHypSin(err, number, result) \
      oci8_OCINumberHypSin(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberHypSin;
#define have_OCINumberHypSin oci8_have_OCINumberHypSin
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberHypSin (1)
#else
#define have_OCINumberHypSin (0)
#endif

/*
 * OCINumberHypTan
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberHypTan(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberHypTan
#define OCINumberHypTan(err, number, result) \
      oci8_OCINumberHypTan(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberHypTan;
#define have_OCINumberHypTan oci8_have_OCINumberHypTan
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberHypTan (1)
#else
#define have_OCINumberHypTan (0)
#endif

/*
 * OCINumberIntPower
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberIntPower(OCIError *err, CONST OCINumber *base, CONST sword exp, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberIntPower
#define OCINumberIntPower(err, base, exp, result) \
      oci8_OCINumberIntPower(err, base, exp, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberIntPower;
#define have_OCINumberIntPower oci8_have_OCINumberIntPower
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberIntPower (1)
#else
#define have_OCINumberIntPower (0)
#endif

/*
 * OCINumberIsZero
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberIsZero(OCIError *err, CONST OCINumber *number, boolean *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberIsZero
#define OCINumberIsZero(err, number, result) \
      oci8_OCINumberIsZero(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberIsZero;
#define have_OCINumberIsZero oci8_have_OCINumberIsZero
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberIsZero (1)
#else
#define have_OCINumberIsZero (0)
#endif

/*
 * OCINumberLn
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberLn(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberLn
#define OCINumberLn(err, number, result) \
      oci8_OCINumberLn(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberLn;
#define have_OCINumberLn oci8_have_OCINumberLn
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberLn (1)
#else
#define have_OCINumberLn (0)
#endif

/*
 * OCINumberLog
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberLog(OCIError *err, CONST OCINumber *base, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberLog
#define OCINumberLog(err, base, number, result) \
      oci8_OCINumberLog(err, base, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberLog;
#define have_OCINumberLog oci8_have_OCINumberLog
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberLog (1)
#else
#define have_OCINumberLog (0)
#endif

/*
 * OCINumberMod
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberMod(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberMod
#define OCINumberMod(err, number1, number2, result) \
      oci8_OCINumberMod(err, number1, number2, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberMod;
#define have_OCINumberMod oci8_have_OCINumberMod
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberMod (1)
#else
#define have_OCINumberMod (0)
#endif

/*
 * OCINumberMul
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberMul(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberMul
#define OCINumberMul(err, number1, number2, result) \
      oci8_OCINumberMul(err, number1, number2, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberMul;
#define have_OCINumberMul oci8_have_OCINumberMul
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberMul (1)
#else
#define have_OCINumberMul (0)
#endif

/*
 * OCINumberNeg
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberNeg(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberNeg
#define OCINumberNeg(err, number, result) \
      oci8_OCINumberNeg(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberNeg;
#define have_OCINumberNeg oci8_have_OCINumberNeg
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberNeg (1)
#else
#define have_OCINumberNeg (0)
#endif

/*
 * OCINumberPower
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberPower(OCIError *err, CONST OCINumber *base, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberPower
#define OCINumberPower(err, base, number, result) \
      oci8_OCINumberPower(err, base, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberPower;
#define have_OCINumberPower oci8_have_OCINumberPower
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberPower (1)
#else
#define have_OCINumberPower (0)
#endif

/*
 * OCINumberRound
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberRound(OCIError *err, CONST OCINumber *number, sword decplace, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberRound
#define OCINumberRound(err, number, decplace, result) \
      oci8_OCINumberRound(err, number, decplace, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberRound;
#define have_OCINumberRound oci8_have_OCINumberRound
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberRound (1)
#else
#define have_OCINumberRound (0)
#endif

/*
 * OCINumberSetZero
 *   version: 8.0.0
 *   remote:  false
 */
void oci8_OCINumberSetZero(OCIError *err, OCINumber *num, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberSetZero
#define OCINumberSetZero(err, num) \
      oci8_OCINumberSetZero(err, num, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberSetZero;
#define have_OCINumberSetZero oci8_have_OCINumberSetZero
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberSetZero (1)
#else
#define have_OCINumberSetZero (0)
#endif

/*
 * OCINumberSin
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberSin(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberSin
#define OCINumberSin(err, number, result) \
      oci8_OCINumberSin(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberSin;
#define have_OCINumberSin oci8_have_OCINumberSin
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberSin (1)
#else
#define have_OCINumberSin (0)
#endif

/*
 * OCINumberSqrt
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberSqrt(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberSqrt
#define OCINumberSqrt(err, number, result) \
      oci8_OCINumberSqrt(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberSqrt;
#define have_OCINumberSqrt oci8_have_OCINumberSqrt
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberSqrt (1)
#else
#define have_OCINumberSqrt (0)
#endif

/*
 * OCINumberSub
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberSub(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberSub
#define OCINumberSub(err, number1, number2, result) \
      oci8_OCINumberSub(err, number1, number2, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberSub;
#define have_OCINumberSub oci8_have_OCINumberSub
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberSub (1)
#else
#define have_OCINumberSub (0)
#endif

/*
 * OCINumberTan
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberTan(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberTan
#define OCINumberTan(err, number, result) \
      oci8_OCINumberTan(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberTan;
#define have_OCINumberTan oci8_have_OCINumberTan
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberTan (1)
#else
#define have_OCINumberTan (0)
#endif

/*
 * OCINumberToInt
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberToInt(OCIError *err, CONST OCINumber *number, uword rsl_length, uword rsl_flag, dvoid *rsl, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberToInt
#define OCINumberToInt(err, number, rsl_length, rsl_flag, rsl) \
      oci8_OCINumberToInt(err, number, rsl_length, rsl_flag, rsl, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberToInt;
#define have_OCINumberToInt oci8_have_OCINumberToInt
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberToInt (1)
#else
#define have_OCINumberToInt (0)
#endif

/*
 * OCINumberToReal
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberToReal(OCIError *err, CONST OCINumber *number, uword rsl_length, dvoid *rsl, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberToReal
#define OCINumberToReal(err, number, rsl_length, rsl) \
      oci8_OCINumberToReal(err, number, rsl_length, rsl, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberToReal;
#define have_OCINumberToReal oci8_have_OCINumberToReal
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberToReal (1)
#else
#define have_OCINumberToReal (0)
#endif

/*
 * OCINumberToText
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberToText(OCIError *err, CONST OCINumber *number, CONST text *fmt, ub4 fmt_length, CONST text *nls_params, ub4 nls_p_length, ub4 *buf_size, text *buf, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberToText
#define OCINumberToText(err, number, fmt, fmt_length, nls_params, nls_p_length, buf_size, buf) \
      oci8_OCINumberToText(err, number, fmt, fmt_length, nls_params, nls_p_length, buf_size, buf, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberToText;
#define have_OCINumberToText oci8_have_OCINumberToText
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberToText (1)
#else
#define have_OCINumberToText (0)
#endif

/*
 * OCINumberTrunc
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCINumberTrunc(OCIError *err, CONST OCINumber *number, sword decplace, OCINumber *resulty, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberTrunc
#define OCINumberTrunc(err, number, decplace, resulty) \
      oci8_OCINumberTrunc(err, number, decplace, resulty, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberTrunc;
#define have_OCINumberTrunc oci8_have_OCINumberTrunc
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCINumberTrunc (1)
#else
#define have_OCINumberTrunc (0)
#endif

/*
 * OCIObjectFree
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIObjectFree(OCIEnv *env, OCIError *err, dvoid *instance, ub2 flags, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIObjectFree
#define OCIObjectFree(env, err, instance, flags) \
      oci8_OCIObjectFree(env, err, instance, flags, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIObjectFree;
#define have_OCIObjectFree oci8_have_OCIObjectFree
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIObjectFree (1)
#else
#define have_OCIObjectFree (0)
#endif

/*
 * OCIObjectGetInd
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIObjectGetInd(OCIEnv *env, OCIError *err, dvoid *instance, dvoid **null_struct, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIObjectGetInd
#define OCIObjectGetInd(env, err, instance, null_struct) \
      oci8_OCIObjectGetInd(env, err, instance, null_struct, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIObjectGetInd;
#define have_OCIObjectGetInd oci8_have_OCIObjectGetInd
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIObjectGetInd (1)
#else
#define have_OCIObjectGetInd (0)
#endif

/*
 * OCIObjectGetTypeRef
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIObjectGetTypeRef(OCIEnv *env, OCIError *err, dvoid *instance, OCIRef *type_ref, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIObjectGetTypeRef
#define OCIObjectGetTypeRef(env, err, instance, type_ref) \
      oci8_OCIObjectGetTypeRef(env, err, instance, type_ref, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIObjectGetTypeRef;
#define have_OCIObjectGetTypeRef oci8_have_OCIObjectGetTypeRef
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIObjectGetTypeRef (1)
#else
#define have_OCIObjectGetTypeRef (0)
#endif

/*
 * OCIObjectNew
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIObjectNew(OCIEnv *env, OCIError *err, CONST OCISvcCtx *svc, OCITypeCode typecode, OCIType *tdo, dvoid *table, OCIDuration duration, boolean value, dvoid **instance, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIObjectNew
#define OCIObjectNew(env, err, svc, typecode, tdo, table, duration, value, instance) \
      oci8_OCIObjectNew(env, err, svc, typecode, tdo, table, duration, value, instance, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIObjectNew;
#define have_OCIObjectNew oci8_have_OCIObjectNew
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIObjectNew (1)
#else
#define have_OCIObjectNew (0)
#endif

/*
 * OCIObjectPin
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCIObjectPin_nb(oci8_svcctx_t *svcctx, OCIEnv *env, OCIError *err, OCIRef *object_ref, OCIComplexObject *corhdl, OCIPinOpt pin_option, OCIDuration pin_duration, OCILockOpt lock_option, dvoid **object, const char *file, int line);
#define OCIObjectPin_nb(svcctx, env, err, object_ref, corhdl, pin_option, pin_duration, lock_option, object) \
      oci8_OCIObjectPin_nb(svcctx, env, err, object_ref, corhdl, pin_option, pin_duration, lock_option, object, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIObjectPin_nb;
#define have_OCIObjectPin_nb oci8_have_OCIObjectPin_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIObjectPin_nb (1)
#else
#define have_OCIObjectPin_nb (0)
#endif

/*
 * OCIObjectUnpin
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIObjectUnpin(OCIEnv *env, OCIError *err, dvoid *object, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIObjectUnpin
#define OCIObjectUnpin(env, err, object) \
      oci8_OCIObjectUnpin(env, err, object, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIObjectUnpin;
#define have_OCIObjectUnpin oci8_have_OCIObjectUnpin
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIObjectUnpin (1)
#else
#define have_OCIObjectUnpin (0)
#endif

/*
 * OCIParamGet
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIParamGet(CONST dvoid *hndlp, ub4 htype, OCIError *errhp, dvoid **parmdpp, ub4 pos, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIParamGet
#define OCIParamGet(hndlp, htype, errhp, parmdpp, pos) \
      oci8_OCIParamGet(hndlp, htype, errhp, parmdpp, pos, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIParamGet;
#define have_OCIParamGet oci8_have_OCIParamGet
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIParamGet (1)
#else
#define have_OCIParamGet (0)
#endif

/*
 * OCIRawAssignBytes
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIRawAssignBytes(OCIEnv *env, OCIError *err, CONST ub1 *rhs, ub4 rhs_len, OCIRaw **lhs, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIRawAssignBytes
#define OCIRawAssignBytes(env, err, rhs, rhs_len, lhs) \
      oci8_OCIRawAssignBytes(env, err, rhs, rhs_len, lhs, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIRawAssignBytes;
#define have_OCIRawAssignBytes oci8_have_OCIRawAssignBytes
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIRawAssignBytes (1)
#else
#define have_OCIRawAssignBytes (0)
#endif

/*
 * OCIRawPtr
 *   version: 8.0.0
 *   remote:  false
 */
ub1 * oci8_OCIRawPtr(OCIEnv *env, CONST OCIRaw *raw, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIRawPtr
#define OCIRawPtr(env, raw) \
      oci8_OCIRawPtr(env, raw, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIRawPtr;
#define have_OCIRawPtr oci8_have_OCIRawPtr
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIRawPtr (1)
#else
#define have_OCIRawPtr (0)
#endif

/*
 * OCIRawSize
 *   version: 8.0.0
 *   remote:  false
 */
ub4 oci8_OCIRawSize(OCIEnv *env, CONST OCIRaw *raw, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIRawSize
#define OCIRawSize(env, raw) \
      oci8_OCIRawSize(env, raw, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIRawSize;
#define have_OCIRawSize oci8_have_OCIRawSize
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIRawSize (1)
#else
#define have_OCIRawSize (0)
#endif

/*
 * OCIServerAttach
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCIServerAttach_nb(oci8_svcctx_t *svcctx, OCIServer *srvhp, OCIError *errhp, CONST text *dblink, sb4 dblink_len, ub4 mode, const char *file, int line);
#define OCIServerAttach_nb(svcctx, srvhp, errhp, dblink, dblink_len, mode) \
      oci8_OCIServerAttach_nb(svcctx, srvhp, errhp, dblink, dblink_len, mode, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIServerAttach_nb;
#define have_OCIServerAttach_nb oci8_have_OCIServerAttach_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIServerAttach_nb (1)
#else
#define have_OCIServerAttach_nb (0)
#endif

/*
 * OCIServerDetach
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIServerDetach(OCIServer *srvhp, OCIError *errhp, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIServerDetach
#define OCIServerDetach(srvhp, errhp, mode) \
      oci8_OCIServerDetach(srvhp, errhp, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIServerDetach;
#define have_OCIServerDetach oci8_have_OCIServerDetach
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIServerDetach (1)
#else
#define have_OCIServerDetach (0)
#endif

/*
 * OCIServerVersion
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIServerVersion(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIServerVersion
#define OCIServerVersion(hndlp, errhp, bufp, bufsz, hndltype) \
      oci8_OCIServerVersion(hndlp, errhp, bufp, bufsz, hndltype, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIServerVersion;
#define have_OCIServerVersion oci8_have_OCIServerVersion
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIServerVersion (1)
#else
#define have_OCIServerVersion (0)
#endif

/*
 * OCISessionBegin
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCISessionBegin_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCISession *usrhp, ub4 credt, ub4 mode, const char *file, int line);
#define OCISessionBegin_nb(svcctx, svchp, errhp, usrhp, credt, mode) \
      oci8_OCISessionBegin_nb(svcctx, svchp, errhp, usrhp, credt, mode, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCISessionBegin_nb;
#define have_OCISessionBegin_nb oci8_have_OCISessionBegin_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCISessionBegin_nb (1)
#else
#define have_OCISessionBegin_nb (0)
#endif

/*
 * OCISessionEnd
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCISessionEnd(OCISvcCtx *svchp, OCIError *errhp, OCISession *usrhp, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCISessionEnd
#define OCISessionEnd(svchp, errhp, usrhp, mode) \
      oci8_OCISessionEnd(svchp, errhp, usrhp, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCISessionEnd;
#define have_OCISessionEnd oci8_have_OCISessionEnd
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCISessionEnd (1)
#else
#define have_OCISessionEnd (0)
#endif

/*
 * OCIStmtExecute
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCIStmtExecute_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIStmt *stmtp, OCIError *errhp, ub4 iters, ub4 rowoff, CONST OCISnapshot *snap_in, OCISnapshot *snap_out, ub4 mode, const char *file, int line);
#define OCIStmtExecute_nb(svcctx, svchp, stmtp, errhp, iters, rowoff, snap_in, snap_out, mode) \
      oci8_OCIStmtExecute_nb(svcctx, svchp, stmtp, errhp, iters, rowoff, snap_in, snap_out, mode, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIStmtExecute_nb;
#define have_OCIStmtExecute_nb oci8_have_OCIStmtExecute_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIStmtExecute_nb (1)
#else
#define have_OCIStmtExecute_nb (0)
#endif

/*
 * OCIStmtFetch
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCIStmtFetch_nb(oci8_svcctx_t *svcctx, OCIStmt *stmtp, OCIError *errhp, ub4 nrows, ub2 orientation, ub4 mode, const char *file, int line);
#define OCIStmtFetch_nb(svcctx, stmtp, errhp, nrows, orientation, mode) \
      oci8_OCIStmtFetch_nb(svcctx, stmtp, errhp, nrows, orientation, mode, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIStmtFetch_nb;
#define have_OCIStmtFetch_nb oci8_have_OCIStmtFetch_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIStmtFetch_nb (1)
#else
#define have_OCIStmtFetch_nb (0)
#endif

/*
 * OCIStringAssignText
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCIStringAssignText(OCIEnv *env, OCIError *err, CONST text *rhs, ub4 rhs_len, OCIString **lhs, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIStringAssignText
#define OCIStringAssignText(env, err, rhs, rhs_len, lhs) \
      oci8_OCIStringAssignText(env, err, rhs, rhs_len, lhs, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIStringAssignText;
#define have_OCIStringAssignText oci8_have_OCIStringAssignText
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIStringAssignText (1)
#else
#define have_OCIStringAssignText (0)
#endif

/*
 * OCIStringPtr
 *   version: 8.0.0
 *   remote:  false
 */
text * oci8_OCIStringPtr(OCIEnv *env, CONST OCIString *vs, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIStringPtr
#define OCIStringPtr(env, vs) \
      oci8_OCIStringPtr(env, vs, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIStringPtr;
#define have_OCIStringPtr oci8_have_OCIStringPtr
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIStringPtr (1)
#else
#define have_OCIStringPtr (0)
#endif

/*
 * OCIStringSize
 *   version: 8.0.0
 *   remote:  false
 */
ub4 oci8_OCIStringSize(OCIEnv *env, CONST OCIString *vs, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIStringSize
#define OCIStringSize(env, vs) \
      oci8_OCIStringSize(env, vs, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIStringSize;
#define have_OCIStringSize oci8_have_OCIStringSize
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCIStringSize (1)
#else
#define have_OCIStringSize (0)
#endif

/*
 * OCITransCommit
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCITransCommit_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, ub4 flags, const char *file, int line);
#define OCITransCommit_nb(svcctx, svchp, errhp, flags) \
      oci8_OCITransCommit_nb(svcctx, svchp, errhp, flags, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCITransCommit_nb;
#define have_OCITransCommit_nb oci8_have_OCITransCommit_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCITransCommit_nb (1)
#else
#define have_OCITransCommit_nb (0)
#endif

/*
 * OCITransRollback
 *   version: 8.0.0
 *   remote:  false
 */
sword oci8_OCITransRollback(OCISvcCtx *svchp, OCIError *errhp, ub4 flags, const char *file, int line);
#ifndef API_WRAP_C
#undef OCITransRollback
#define OCITransRollback(svchp, errhp, flags) \
      oci8_OCITransRollback(svchp, errhp, flags, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCITransRollback;
#define have_OCITransRollback oci8_have_OCITransRollback
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCITransRollback (1)
#else
#define have_OCITransRollback (0)
#endif

/*
 * OCITransRollback
 *   version: 8.0.0
 *   remote:  true
 */
sword oci8_OCITransRollback_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, ub4 flags, const char *file, int line);
#define OCITransRollback_nb(svcctx, svchp, errhp, flags) \
      oci8_OCITransRollback_nb(svcctx, svchp, errhp, flags, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCITransRollback_nb;
#define have_OCITransRollback_nb oci8_have_OCITransRollback_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCITransRollback_nb (1)
#else
#define have_OCITransRollback_nb (0)
#endif

/*
 * OCITypeTypeCode
 *   version: 8.0.0
 *   remote:  false
 */
OCITypeCode oci8_OCITypeTypeCode(OCIEnv *env, OCIError *err, CONST OCIType *tdo, const char *file, int line);
#ifndef API_WRAP_C
#undef OCITypeTypeCode
#define OCITypeTypeCode(env, err, tdo) \
      oci8_OCITypeTypeCode(env, err, tdo, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCITypeTypeCode;
#define have_OCITypeTypeCode oci8_have_OCITypeTypeCode
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_0
#define have_OCITypeTypeCode (1)
#else
#define have_OCITypeTypeCode (0)
#endif

/*
 * OCIEnvCreate
 *   version: 8.1.0
 *   remote:  false
 */
sword oci8_OCIEnvCreate(OCIEnv **envp, ub4 mode, dvoid *ctxp, dvoid *(*malocfp)(dvoid *ctxp, size_t size), dvoid *(*ralocfp)(dvoid *ctxp, dvoid *memptr, size_t newsize), void   (*mfreefp)(dvoid *ctxp, dvoid *memptr), size_t xtramem_sz, dvoid **usrmempp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIEnvCreate
#define OCIEnvCreate(envp, mode, ctxp, malocfp, ralocfp, mfreefp, xtramem_sz, usrmempp) \
      oci8_OCIEnvCreate(envp, mode, ctxp, malocfp, ralocfp, mfreefp, xtramem_sz, usrmempp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIEnvCreate;
#define have_OCIEnvCreate oci8_have_OCIEnvCreate
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCIEnvCreate (1)
#else
#define have_OCIEnvCreate (0)
#endif

/*
 * OCILobClose
 *   version: 8.1.0
 *   remote:  true
 */
sword oci8_OCILobClose_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, const char *file, int line);
#define OCILobClose_nb(svcctx, svchp, errhp, locp) \
      oci8_OCILobClose_nb(svcctx, svchp, errhp, locp, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobClose_nb;
#define have_OCILobClose_nb oci8_have_OCILobClose_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCILobClose_nb (1)
#else
#define have_OCILobClose_nb (0)
#endif

/*
 * OCILobCreateTemporary
 *   version: 8.1.0
 *   remote:  true
 */
sword oci8_OCILobCreateTemporary_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub2 csid, ub1 csfrm, ub1 lobtype, boolean cache, OCIDuration duration, const char *file, int line);
#define OCILobCreateTemporary_nb(svcctx, svchp, errhp, locp, csid, csfrm, lobtype, cache, duration) \
      oci8_OCILobCreateTemporary_nb(svcctx, svchp, errhp, locp, csid, csfrm, lobtype, cache, duration, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobCreateTemporary_nb;
#define have_OCILobCreateTemporary_nb oci8_have_OCILobCreateTemporary_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCILobCreateTemporary_nb (1)
#else
#define have_OCILobCreateTemporary_nb (0)
#endif

/*
 * OCILobFreeTemporary
 *   version: 8.1.0
 *   remote:  false
 */
sword oci8_OCILobFreeTemporary(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCILobFreeTemporary
#define OCILobFreeTemporary(svchp, errhp, locp) \
      oci8_OCILobFreeTemporary(svchp, errhp, locp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobFreeTemporary;
#define have_OCILobFreeTemporary oci8_have_OCILobFreeTemporary
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCILobFreeTemporary (1)
#else
#define have_OCILobFreeTemporary (0)
#endif

/*
 * OCILobGetChunkSize
 *   version: 8.1.0
 *   remote:  true
 */
sword oci8_OCILobGetChunkSize_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub4 *chunksizep, const char *file, int line);
#define OCILobGetChunkSize_nb(svcctx, svchp, errhp, locp, chunksizep) \
      oci8_OCILobGetChunkSize_nb(svcctx, svchp, errhp, locp, chunksizep, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobGetChunkSize_nb;
#define have_OCILobGetChunkSize_nb oci8_have_OCILobGetChunkSize_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCILobGetChunkSize_nb (1)
#else
#define have_OCILobGetChunkSize_nb (0)
#endif

/*
 * OCILobIsTemporary
 *   version: 8.1.0
 *   remote:  false
 */
sword oci8_OCILobIsTemporary(OCIEnv *envp, OCIError *errhp, OCILobLocator *locp, boolean *is_temporary, const char *file, int line);
#ifndef API_WRAP_C
#undef OCILobIsTemporary
#define OCILobIsTemporary(envp, errhp, locp, is_temporary) \
      oci8_OCILobIsTemporary(envp, errhp, locp, is_temporary, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobIsTemporary;
#define have_OCILobIsTemporary oci8_have_OCILobIsTemporary
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCILobIsTemporary (1)
#else
#define have_OCILobIsTemporary (0)
#endif

/*
 * OCILobLocatorAssign
 *   version: 8.1.0
 *   remote:  true
 */
sword oci8_OCILobLocatorAssign_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, CONST OCILobLocator *src_locp, OCILobLocator **dst_locpp, const char *file, int line);
#define OCILobLocatorAssign_nb(svcctx, svchp, errhp, src_locp, dst_locpp) \
      oci8_OCILobLocatorAssign_nb(svcctx, svchp, errhp, src_locp, dst_locpp, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobLocatorAssign_nb;
#define have_OCILobLocatorAssign_nb oci8_have_OCILobLocatorAssign_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCILobLocatorAssign_nb (1)
#else
#define have_OCILobLocatorAssign_nb (0)
#endif

/*
 * OCILobOpen
 *   version: 8.1.0
 *   remote:  true
 */
sword oci8_OCILobOpen_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub1 mode, const char *file, int line);
#define OCILobOpen_nb(svcctx, svchp, errhp, locp, mode) \
      oci8_OCILobOpen_nb(svcctx, svchp, errhp, locp, mode, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobOpen_nb;
#define have_OCILobOpen_nb oci8_have_OCILobOpen_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCILobOpen_nb (1)
#else
#define have_OCILobOpen_nb (0)
#endif

/*
 * OCIMessageGet
 *   version: 8.1.0
 *   remote:  false
 */
OraText * oci8_OCIMessageGet(OCIMsg *msgh, ub4 msgno, OraText *msgbuf, size_t buflen, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIMessageGet
#define OCIMessageGet(msgh, msgno, msgbuf, buflen) \
      oci8_OCIMessageGet(msgh, msgno, msgbuf, buflen, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIMessageGet;
#define have_OCIMessageGet oci8_have_OCIMessageGet
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCIMessageGet (1)
#else
#define have_OCIMessageGet (0)
#endif

/*
 * OCIMessageOpen
 *   version: 8.1.0
 *   remote:  false
 */
sword oci8_OCIMessageOpen(dvoid *envhp, OCIError *errhp, OCIMsg **msghp, CONST OraText *product, CONST OraText *facility, OCIDuration dur, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIMessageOpen
#define OCIMessageOpen(envhp, errhp, msghp, product, facility, dur) \
      oci8_OCIMessageOpen(envhp, errhp, msghp, product, facility, dur, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIMessageOpen;
#define have_OCIMessageOpen oci8_have_OCIMessageOpen
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCIMessageOpen (1)
#else
#define have_OCIMessageOpen (0)
#endif

/*
 * OCINumberIsInt
 *   version: 8.1.0
 *   remote:  false
 */
sword oci8_OCINumberIsInt(OCIError *err, CONST OCINumber *number, boolean *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberIsInt
#define OCINumberIsInt(err, number, result) \
      oci8_OCINumberIsInt(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberIsInt;
#define have_OCINumberIsInt oci8_have_OCINumberIsInt
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCINumberIsInt (1)
#else
#define have_OCINumberIsInt (0)
#endif

/*
 * OCINumberPrec
 *   version: 8.1.0
 *   remote:  false
 */
sword oci8_OCINumberPrec(OCIError *err, CONST OCINumber *number, eword nDigs, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberPrec
#define OCINumberPrec(err, number, nDigs, result) \
      oci8_OCINumberPrec(err, number, nDigs, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberPrec;
#define have_OCINumberPrec oci8_have_OCINumberPrec
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCINumberPrec (1)
#else
#define have_OCINumberPrec (0)
#endif

/*
 * OCINumberSetPi
 *   version: 8.1.0
 *   remote:  false
 */
void oci8_OCINumberSetPi(OCIError *err, OCINumber *num, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberSetPi
#define OCINumberSetPi(err, num) \
      oci8_OCINumberSetPi(err, num, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberSetPi;
#define have_OCINumberSetPi oci8_have_OCINumberSetPi
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCINumberSetPi (1)
#else
#define have_OCINumberSetPi (0)
#endif

/*
 * OCINumberShift
 *   version: 8.1.0
 *   remote:  false
 */
sword oci8_OCINumberShift(OCIError *err, CONST OCINumber *number, CONST sword nDig, OCINumber *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberShift
#define OCINumberShift(err, number, nDig, result) \
      oci8_OCINumberShift(err, number, nDig, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberShift;
#define have_OCINumberShift oci8_have_OCINumberShift
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCINumberShift (1)
#else
#define have_OCINumberShift (0)
#endif

/*
 * OCINumberSign
 *   version: 8.1.0
 *   remote:  false
 */
sword oci8_OCINumberSign(OCIError *err, CONST OCINumber *number, sword *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINumberSign
#define OCINumberSign(err, number, result) \
      oci8_OCINumberSign(err, number, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINumberSign;
#define have_OCINumberSign oci8_have_OCINumberSign
#elif ORACLE_CLIENT_VERSION >= ORAVER_8_1
#define have_OCINumberSign (1)
#else
#define have_OCINumberSign (0)
#endif

/*
 * OCIConnectionPoolCreate
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIConnectionPoolCreate(OCIEnv *envhp, OCIError *errhp, OCICPool *poolhp, OraText **poolName, sb4 *poolNameLen, const OraText *dblink, sb4 dblinkLen, ub4 connMin, ub4 connMax, ub4 connIncr, const OraText *poolUserName, sb4 poolUserLen, const OraText *poolPassword, sb4 poolPassLen, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIConnectionPoolCreate
#define OCIConnectionPoolCreate(envhp, errhp, poolhp, poolName, poolNameLen, dblink, dblinkLen, connMin, connMax, connIncr, poolUserName, poolUserLen, poolPassword, poolPassLen, mode) \
      oci8_OCIConnectionPoolCreate(envhp, errhp, poolhp, poolName, poolNameLen, dblink, dblinkLen, connMin, connMax, connIncr, poolUserName, poolUserLen, poolPassword, poolPassLen, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIConnectionPoolCreate;
#define have_OCIConnectionPoolCreate oci8_have_OCIConnectionPoolCreate
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIConnectionPoolCreate (1)
#else
#define have_OCIConnectionPoolCreate (0)
#endif

/*
 * OCIConnectionPoolDestroy
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIConnectionPoolDestroy(OCICPool *poolhp, OCIError *errhp, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIConnectionPoolDestroy
#define OCIConnectionPoolDestroy(poolhp, errhp, mode) \
      oci8_OCIConnectionPoolDestroy(poolhp, errhp, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIConnectionPoolDestroy;
#define have_OCIConnectionPoolDestroy oci8_have_OCIConnectionPoolDestroy
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIConnectionPoolDestroy (1)
#else
#define have_OCIConnectionPoolDestroy (0)
#endif

/*
 * OCIDateTimeConstruct
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIDateTimeConstruct(dvoid  *hndl, OCIError *err, OCIDateTime *datetime, sb2 yr, ub1 mnth, ub1 dy, ub1 hr, ub1 mm, ub1 ss, ub4 fsec, OraText *timezone, size_t timezone_length, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDateTimeConstruct
#define OCIDateTimeConstruct(hndl, err, datetime, yr, mnth, dy, hr, mm, ss, fsec, timezone, timezone_length) \
      oci8_OCIDateTimeConstruct(hndl, err, datetime, yr, mnth, dy, hr, mm, ss, fsec, timezone, timezone_length, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDateTimeConstruct;
#define have_OCIDateTimeConstruct oci8_have_OCIDateTimeConstruct
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIDateTimeConstruct (1)
#else
#define have_OCIDateTimeConstruct (0)
#endif

/*
 * OCIDateTimeGetDate
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIDateTimeGetDate(dvoid *hndl, OCIError *err, CONST OCIDateTime *date, sb2 *yr, ub1 *mnth, ub1 *dy, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDateTimeGetDate
#define OCIDateTimeGetDate(hndl, err, date, yr, mnth, dy) \
      oci8_OCIDateTimeGetDate(hndl, err, date, yr, mnth, dy, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDateTimeGetDate;
#define have_OCIDateTimeGetDate oci8_have_OCIDateTimeGetDate
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIDateTimeGetDate (1)
#else
#define have_OCIDateTimeGetDate (0)
#endif

/*
 * OCIDateTimeGetTime
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIDateTimeGetTime(dvoid *hndl, OCIError *err, OCIDateTime *datetime, ub1 *hr, ub1 *mm, ub1 *ss, ub4 *fsec, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDateTimeGetTime
#define OCIDateTimeGetTime(hndl, err, datetime, hr, mm, ss, fsec) \
      oci8_OCIDateTimeGetTime(hndl, err, datetime, hr, mm, ss, fsec, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDateTimeGetTime;
#define have_OCIDateTimeGetTime oci8_have_OCIDateTimeGetTime
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIDateTimeGetTime (1)
#else
#define have_OCIDateTimeGetTime (0)
#endif

/*
 * OCIDateTimeGetTimeZoneOffset
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIDateTimeGetTimeZoneOffset(dvoid *hndl, OCIError *err, CONST OCIDateTime *datetime, sb1 *hr, sb1 *mm, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIDateTimeGetTimeZoneOffset
#define OCIDateTimeGetTimeZoneOffset(hndl, err, datetime, hr, mm) \
      oci8_OCIDateTimeGetTimeZoneOffset(hndl, err, datetime, hr, mm, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIDateTimeGetTimeZoneOffset;
#define have_OCIDateTimeGetTimeZoneOffset oci8_have_OCIDateTimeGetTimeZoneOffset
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIDateTimeGetTimeZoneOffset (1)
#else
#define have_OCIDateTimeGetTimeZoneOffset (0)
#endif

/*
 * OCIIntervalGetDaySecond
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIIntervalGetDaySecond(dvoid *hndl, OCIError *err, sb4 *dy, sb4 *hr, sb4 *mm, sb4 *ss, sb4 *fsec, CONST OCIInterval *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIIntervalGetDaySecond
#define OCIIntervalGetDaySecond(hndl, err, dy, hr, mm, ss, fsec, result) \
      oci8_OCIIntervalGetDaySecond(hndl, err, dy, hr, mm, ss, fsec, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIIntervalGetDaySecond;
#define have_OCIIntervalGetDaySecond oci8_have_OCIIntervalGetDaySecond
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIIntervalGetDaySecond (1)
#else
#define have_OCIIntervalGetDaySecond (0)
#endif

/*
 * OCIIntervalGetYearMonth
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIIntervalGetYearMonth(dvoid *hndl, OCIError *err, sb4 *yr, sb4 *mnth, CONST OCIInterval *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIIntervalGetYearMonth
#define OCIIntervalGetYearMonth(hndl, err, yr, mnth, result) \
      oci8_OCIIntervalGetYearMonth(hndl, err, yr, mnth, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIIntervalGetYearMonth;
#define have_OCIIntervalGetYearMonth oci8_have_OCIIntervalGetYearMonth
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIIntervalGetYearMonth (1)
#else
#define have_OCIIntervalGetYearMonth (0)
#endif

/*
 * OCIIntervalSetDaySecond
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIIntervalSetDaySecond(dvoid *hndl, OCIError *err, sb4 dy, sb4 hr, sb4 mm, sb4 ss, sb4 fsec, OCIInterval *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIIntervalSetDaySecond
#define OCIIntervalSetDaySecond(hndl, err, dy, hr, mm, ss, fsec, result) \
      oci8_OCIIntervalSetDaySecond(hndl, err, dy, hr, mm, ss, fsec, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIIntervalSetDaySecond;
#define have_OCIIntervalSetDaySecond oci8_have_OCIIntervalSetDaySecond
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIIntervalSetDaySecond (1)
#else
#define have_OCIIntervalSetDaySecond (0)
#endif

/*
 * OCIIntervalSetYearMonth
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIIntervalSetYearMonth(dvoid *hndl, OCIError *err, sb4 yr, sb4 mnth, OCIInterval *result, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIIntervalSetYearMonth
#define OCIIntervalSetYearMonth(hndl, err, yr, mnth, result) \
      oci8_OCIIntervalSetYearMonth(hndl, err, yr, mnth, result, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIIntervalSetYearMonth;
#define have_OCIIntervalSetYearMonth oci8_have_OCIIntervalSetYearMonth
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIIntervalSetYearMonth (1)
#else
#define have_OCIIntervalSetYearMonth (0)
#endif

/*
 * OCIRowidToChar
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIRowidToChar(OCIRowid *rowidDesc, OraText *outbfp, ub2 *outbflp, OCIError *errhp, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIRowidToChar
#define OCIRowidToChar(rowidDesc, outbfp, outbflp, errhp) \
      oci8_OCIRowidToChar(rowidDesc, outbfp, outbflp, errhp, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIRowidToChar;
#define have_OCIRowidToChar oci8_have_OCIRowidToChar
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIRowidToChar (1)
#else
#define have_OCIRowidToChar (0)
#endif

/*
 * OCIServerRelease
 *   version: 9.0.0
 *   remote:  false
 */
sword oci8_OCIServerRelease(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype, ub4 *version, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIServerRelease
#define OCIServerRelease(hndlp, errhp, bufp, bufsz, hndltype, version) \
      oci8_OCIServerRelease(hndlp, errhp, bufp, bufsz, hndltype, version, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIServerRelease;
#define have_OCIServerRelease oci8_have_OCIServerRelease
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_0
#define have_OCIServerRelease (1)
#else
#define have_OCIServerRelease (0)
#endif

/*
 * OCINlsCharSetIdToName
 *   version: 9.2.0
 *   remote:  false
 */
sword oci8_OCINlsCharSetIdToName(dvoid *envhp, oratext *buf, size_t buflen, ub2 id, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINlsCharSetIdToName
#define OCINlsCharSetIdToName(envhp, buf, buflen, id) \
      oci8_OCINlsCharSetIdToName(envhp, buf, buflen, id, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINlsCharSetIdToName;
#define have_OCINlsCharSetIdToName oci8_have_OCINlsCharSetIdToName
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_2
#define have_OCINlsCharSetIdToName (1)
#else
#define have_OCINlsCharSetIdToName (0)
#endif

/*
 * OCINlsCharSetNameToId
 *   version: 9.2.0
 *   remote:  false
 */
ub2 oci8_OCINlsCharSetNameToId(dvoid *envhp, const oratext *name, const char *file, int line);
#ifndef API_WRAP_C
#undef OCINlsCharSetNameToId
#define OCINlsCharSetNameToId(envhp, name) \
      oci8_OCINlsCharSetNameToId(envhp, name, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCINlsCharSetNameToId;
#define have_OCINlsCharSetNameToId oci8_have_OCINlsCharSetNameToId
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_2
#define have_OCINlsCharSetNameToId (1)
#else
#define have_OCINlsCharSetNameToId (0)
#endif

/*
 * OCIStmtPrepare2
 *   version: 9.2.0
 *   remote:  false
 */
sword oci8_OCIStmtPrepare2(OCISvcCtx *svchp, OCIStmt **stmtp, OCIError *errhp, const OraText *stmt, ub4 stmt_len, const OraText *key, ub4 key_len, ub4 language, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIStmtPrepare2
#define OCIStmtPrepare2(svchp, stmtp, errhp, stmt, stmt_len, key, key_len, language, mode) \
      oci8_OCIStmtPrepare2(svchp, stmtp, errhp, stmt, stmt_len, key, key_len, language, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIStmtPrepare2;
#define have_OCIStmtPrepare2 oci8_have_OCIStmtPrepare2
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_2
#define have_OCIStmtPrepare2 (1)
#else
#define have_OCIStmtPrepare2 (0)
#endif

/*
 * OCIStmtRelease
 *   version: 9.2.0
 *   remote:  false
 */
sword oci8_OCIStmtRelease(OCIStmt *stmtp, OCIError *errhp, const OraText *key, ub4 key_len, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIStmtRelease
#define OCIStmtRelease(stmtp, errhp, key, key_len, mode) \
      oci8_OCIStmtRelease(stmtp, errhp, key, key_len, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIStmtRelease;
#define have_OCIStmtRelease oci8_have_OCIStmtRelease
#elif ORACLE_CLIENT_VERSION >= ORAVER_9_2
#define have_OCIStmtRelease (1)
#else
#define have_OCIStmtRelease (0)
#endif

/*
 * OCILobGetLength2
 *   version: 10.1.0
 *   remote:  true
 */
sword oci8_OCILobGetLength2_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *lenp, const char *file, int line);
#define OCILobGetLength2_nb(svcctx, svchp, errhp, locp, lenp) \
      oci8_OCILobGetLength2_nb(svcctx, svchp, errhp, locp, lenp, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobGetLength2_nb;
#define have_OCILobGetLength2_nb oci8_have_OCILobGetLength2_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_10_1
#define have_OCILobGetLength2_nb (1)
#else
#define have_OCILobGetLength2_nb (0)
#endif

/*
 * OCILobRead2
 *   version: 10.1.0
 *   remote:  true
 */
sword oci8_OCILobRead2_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *byte_amtp, oraub8 *char_amtp, oraub8 offset, dvoid *bufp, oraub8 bufl, ub1 piece, dvoid *ctxp, OCICallbackLobRead2 cbfp, ub2 csid, ub1 csfrm, const char *file, int line);
#define OCILobRead2_nb(svcctx, svchp, errhp, locp, byte_amtp, char_amtp, offset, bufp, bufl, piece, ctxp, cbfp, csid, csfrm) \
      oci8_OCILobRead2_nb(svcctx, svchp, errhp, locp, byte_amtp, char_amtp, offset, bufp, bufl, piece, ctxp, cbfp, csid, csfrm, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobRead2_nb;
#define have_OCILobRead2_nb oci8_have_OCILobRead2_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_10_1
#define have_OCILobRead2_nb (1)
#else
#define have_OCILobRead2_nb (0)
#endif

/*
 * OCILobTrim2
 *   version: 10.1.0
 *   remote:  true
 */
sword oci8_OCILobTrim2_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 newlen, const char *file, int line);
#define OCILobTrim2_nb(svcctx, svchp, errhp, locp, newlen) \
      oci8_OCILobTrim2_nb(svcctx, svchp, errhp, locp, newlen, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobTrim2_nb;
#define have_OCILobTrim2_nb oci8_have_OCILobTrim2_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_10_1
#define have_OCILobTrim2_nb (1)
#else
#define have_OCILobTrim2_nb (0)
#endif

/*
 * OCILobWrite2
 *   version: 10.1.0
 *   remote:  true
 */
sword oci8_OCILobWrite2_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *byte_amtp, oraub8 *char_amtp, oraub8 offset, dvoid *bufp, oraub8 buflen, ub1 piece, dvoid *ctxp, OCICallbackLobWrite2 cbfp, ub2 csid, ub1 csfrm, const char *file, int line);
#define OCILobWrite2_nb(svcctx, svchp, errhp, locp, byte_amtp, char_amtp, offset, bufp, buflen, piece, ctxp, cbfp, csid, csfrm) \
      oci8_OCILobWrite2_nb(svcctx, svchp, errhp, locp, byte_amtp, char_amtp, offset, bufp, buflen, piece, ctxp, cbfp, csid, csfrm, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCILobWrite2_nb;
#define have_OCILobWrite2_nb oci8_have_OCILobWrite2_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_10_1
#define have_OCILobWrite2_nb (1)
#else
#define have_OCILobWrite2_nb (0)
#endif

/*
 * OCIClientVersion
 *   version: 10.2.0
 *   remote:  false
 */
void oci8_OCIClientVersion(sword *major_version, sword *minor_version, sword *update_num, sword *patch_num, sword *port_update_num, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIClientVersion
#define OCIClientVersion(major_version, minor_version, update_num, patch_num, port_update_num) \
      oci8_OCIClientVersion(major_version, minor_version, update_num, patch_num, port_update_num, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIClientVersion;
#define have_OCIClientVersion oci8_have_OCIClientVersion
#elif ORACLE_CLIENT_VERSION >= ORAVER_10_2
#define have_OCIClientVersion (1)
#else
#define have_OCIClientVersion (0)
#endif

/*
 * OCIPing
 *   version: 10.2.0
 *   remote:  true
 */
sword oci8_OCIPing_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, ub4 mode, const char *file, int line);
#define OCIPing_nb(svcctx, svchp, errhp, mode) \
      oci8_OCIPing_nb(svcctx, svchp, errhp, mode, __FILE__, __LINE__)
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIPing_nb;
#define have_OCIPing_nb oci8_have_OCIPing_nb
#elif ORACLE_CLIENT_VERSION >= ORAVER_10_2
#define have_OCIPing_nb (1)
#else
#define have_OCIPing_nb (0)
#endif

/*
 * OCIServerRelease2
 *   version: 18.0.0
 *   remote:  false
 */
sword oci8_OCIServerRelease2(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype, ub4 *version, ub4 mode, const char *file, int line);
#ifndef API_WRAP_C
#undef OCIServerRelease2
#define OCIServerRelease2(hndlp, errhp, bufp, bufsz, hndltype, version, mode) \
      oci8_OCIServerRelease2(hndlp, errhp, bufp, bufsz, hndltype, version, mode, __FILE__, __LINE__)
#endif
#if defined RUNTIME_API_CHECK
extern int oci8_have_OCIServerRelease2;
#define have_OCIServerRelease2 oci8_have_OCIServerRelease2
#elif ORACLE_CLIENT_VERSION >= ORAVER_18
#define have_OCIServerRelease2 (1)
#else
#define have_OCIServerRelease2 (0)
#endif

#endif /* APIWRAP_H */
