/* -*- c-file-style: "ruby"; indent-tabs-mode: nil -*- */
/*
 * This file was created by apiwrap.rb.
 * Don't edit this file manually.
 */
#define API_WRAP_C 1
#include "apiwrap.h"


/* OCIAttrGet */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIAttrGet_func_t)(CONST dvoid *trgthndlp, ub4 trghndltyp, dvoid *attributep, ub4 *sizep, ub4 attrtype, OCIError *errhp);
static oci8_OCIAttrGet_func_t oci8_OCIAttrGet_func;
#define OCIAttrGet oci8_OCIAttrGet_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIAttrGet(trgthndlp, trghndltyp, attributep, sizep, attrtype, errhp) (0)
#endif

/* OCIAttrSet */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIAttrSet_func_t)(dvoid *trgthndlp, ub4 trghndltyp, dvoid *attributep, ub4 size, ub4 attrtype, OCIError *errhp);
static oci8_OCIAttrSet_func_t oci8_OCIAttrSet_func;
#define OCIAttrSet oci8_OCIAttrSet_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIAttrSet(trgthndlp, trghndltyp, attributep, size, attrtype, errhp) (0)
#endif

/* OCIBindArrayOfStruct */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIBindArrayOfStruct_func_t)(OCIBind *bindp, OCIError *errhp, ub4 pvskip, ub4 indskip, ub4 alskip, ub4 rcskip);
static oci8_OCIBindArrayOfStruct_func_t oci8_OCIBindArrayOfStruct_func;
#define OCIBindArrayOfStruct oci8_OCIBindArrayOfStruct_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIBindArrayOfStruct(bindp, errhp, pvskip, indskip, alskip, rcskip) (0)
#endif

/* OCIBindByName */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIBindByName_func_t)(OCIStmt *stmtp, OCIBind **bindp, OCIError *errhp, CONST text *placeholder, sb4 placeh_len, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *alenp, ub2 *rcodep, ub4 maxarr_len, ub4 *curelep, ub4 mode);
static oci8_OCIBindByName_func_t oci8_OCIBindByName_func;
#define OCIBindByName oci8_OCIBindByName_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIBindByName(stmtp, bindp, errhp, placeholder, placeh_len, valuep, value_sz, dty, indp, alenp, rcodep, maxarr_len, curelep, mode) (0)
#endif

/* OCIBindByPos */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIBindByPos_func_t)(OCIStmt *stmtp, OCIBind **bindp, OCIError *errhp, ub4 position, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *alenp, ub2 *rcodep, ub4 maxarr_len, ub4 *curelep, ub4 mode);
static oci8_OCIBindByPos_func_t oci8_OCIBindByPos_func;
#define OCIBindByPos oci8_OCIBindByPos_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIBindByPos(stmtp, bindp, errhp, position, valuep, value_sz, dty, indp, alenp, rcodep, maxarr_len, curelep, mode) (0)
#endif

/* OCIBindDynamic */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIBindDynamic_func_t)(OCIBind *bindp, OCIError *errhp, void  *ictxp, OCICallbackInBind icbfp, void  *octxp, OCICallbackOutBind ocbfp);
static oci8_OCIBindDynamic_func_t oci8_OCIBindDynamic_func;
#define OCIBindDynamic oci8_OCIBindDynamic_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIBindDynamic(bindp, errhp, ictxp, icbfp, octxp, ocbfp) (0)
#endif

/* OCIBindObject */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIBindObject_func_t)(OCIBind *bindp, OCIError *errhp, CONST OCIType *type, dvoid **pgvpp, ub4 *pvszsp, dvoid **indpp, ub4 *indszp);
static oci8_OCIBindObject_func_t oci8_OCIBindObject_func;
#define OCIBindObject oci8_OCIBindObject_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIBindObject(bindp, errhp, type, pgvpp, pvszsp, indpp, indszp) (0)
#endif

/* OCIBreak */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIBreak_func_t)(dvoid *hndlp, OCIError *errhp);
static oci8_OCIBreak_func_t oci8_OCIBreak_func;
#define OCIBreak oci8_OCIBreak_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIBreak(hndlp, errhp) (0)
#endif

/* OCICollAppend */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCICollAppend_func_t)(OCIEnv *env, OCIError *err, CONST dvoid *elem, CONST dvoid *elemind, OCIColl *coll);
static oci8_OCICollAppend_func_t oci8_OCICollAppend_func;
#define OCICollAppend oci8_OCICollAppend_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCICollAppend(env, err, elem, elemind, coll) (0)
#endif

/* OCICollAssignElem */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCICollAssignElem_func_t)(OCIEnv *env, OCIError *err, sb4 index, CONST dvoid *elem, CONST dvoid *elemind, OCIColl *coll);
static oci8_OCICollAssignElem_func_t oci8_OCICollAssignElem_func;
#define OCICollAssignElem oci8_OCICollAssignElem_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCICollAssignElem(env, err, index, elem, elemind, coll) (0)
#endif

/* OCICollGetElem */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCICollGetElem_func_t)(OCIEnv *env, OCIError *err, CONST OCIColl *coll, sb4 index, boolean *exists, dvoid **elem, dvoid **elemind);
static oci8_OCICollGetElem_func_t oci8_OCICollGetElem_func;
#define OCICollGetElem oci8_OCICollGetElem_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCICollGetElem(env, err, coll, index, exists, elem, elemind) (0)
#endif

/* OCICollSize */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCICollSize_func_t)(OCIEnv *env, OCIError *err, CONST OCIColl *coll, sb4 *size);
static oci8_OCICollSize_func_t oci8_OCICollSize_func;
#define OCICollSize oci8_OCICollSize_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCICollSize(env, err, coll, size) (0)
#endif

/* OCICollTrim */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCICollTrim_func_t)(OCIEnv *env, OCIError *err, sb4 trim_num, OCIColl *coll);
static oci8_OCICollTrim_func_t oci8_OCICollTrim_func;
#define OCICollTrim oci8_OCICollTrim_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCICollTrim(env, err, trim_num, coll) (0)
#endif

/* OCIDefineArrayOfStruct */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDefineArrayOfStruct_func_t)(OCIDefine *defnp, OCIError *errhp, ub4 pvskip, ub4 indskip, ub4 rlskip, ub4 rcskip);
static oci8_OCIDefineArrayOfStruct_func_t oci8_OCIDefineArrayOfStruct_func;
#define OCIDefineArrayOfStruct oci8_OCIDefineArrayOfStruct_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIDefineArrayOfStruct(defnp, errhp, pvskip, indskip, rlskip, rcskip) (0)
#endif

/* OCIDefineByPos */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDefineByPos_func_t)(OCIStmt *stmtp, OCIDefine **defnp, OCIError *errhp, ub4 position, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *rlenp, ub2 *rcodep, ub4 mode);
static oci8_OCIDefineByPos_func_t oci8_OCIDefineByPos_func;
#define OCIDefineByPos oci8_OCIDefineByPos_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIDefineByPos(stmtp, defnp, errhp, position, valuep, value_sz, dty, indp, rlenp, rcodep, mode) (0)
#endif

/* OCIDefineDynamic */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDefineDynamic_func_t)(OCIDefine *defnp, OCIError *errhp, dvoid *octxp, OCICallbackDefine ocbfp);
static oci8_OCIDefineDynamic_func_t oci8_OCIDefineDynamic_func;
#define OCIDefineDynamic oci8_OCIDefineDynamic_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIDefineDynamic(defnp, errhp, octxp, ocbfp) (0)
#endif

/* OCIDefineObject */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDefineObject_func_t)(OCIDefine *defnp, OCIError *errhp, CONST OCIType *type, dvoid **pgvpp, ub4 *pvszsp, dvoid **indpp, ub4 *indszp);
static oci8_OCIDefineObject_func_t oci8_OCIDefineObject_func;
#define OCIDefineObject oci8_OCIDefineObject_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIDefineObject(defnp, errhp, type, pgvpp, pvszsp, indpp, indszp) (0)
#endif

/* OCIDescribeAny */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDescribeAny_func_t)(OCISvcCtx *svchp, OCIError *errhp, dvoid *objptr, ub4 objnm_len, ub1 objptr_typ, ub1 info_level, ub1 objtyp, OCIDescribe *dschp);
static oci8_OCIDescribeAny_func_t oci8_OCIDescribeAny_func;
#define OCIDescribeAny oci8_OCIDescribeAny_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIDescribeAny(svchp, errhp, objptr, objnm_len, objptr_typ, info_level, objtyp, dschp) (0)
#endif

/* OCIDescriptorAlloc */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDescriptorAlloc_func_t)(CONST dvoid *parenth, dvoid **descpp, ub4 type, size_t xtramem_sz, dvoid **usrmempp);
static oci8_OCIDescriptorAlloc_func_t oci8_OCIDescriptorAlloc_func;
#define OCIDescriptorAlloc oci8_OCIDescriptorAlloc_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIDescriptorAlloc(parenth, descpp, type, xtramem_sz, usrmempp) (0)
#endif

/* OCIDescriptorFree */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDescriptorFree_func_t)(dvoid *descp, ub4 type);
static oci8_OCIDescriptorFree_func_t oci8_OCIDescriptorFree_func;
#define OCIDescriptorFree oci8_OCIDescriptorFree_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIDescriptorFree(descp, type) (0)
#endif

/* OCIErrorGet */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIErrorGet_func_t)(dvoid *hndlp, ub4 recordno, text *sqlstate, sb4 *errcodep, text *bufp, ub4 bufsiz, ub4 type);
static oci8_OCIErrorGet_func_t oci8_OCIErrorGet_func;
#define OCIErrorGet oci8_OCIErrorGet_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIErrorGet(hndlp, recordno, sqlstate, errcodep, bufp, bufsiz, type) (0)
#endif

/* OCIHandleAlloc */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIHandleAlloc_func_t)(CONST dvoid *parenth, dvoid **hndlpp, ub4 type, size_t xtramem_sz, dvoid **usrmempp);
static oci8_OCIHandleAlloc_func_t oci8_OCIHandleAlloc_func;
#define OCIHandleAlloc oci8_OCIHandleAlloc_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIHandleAlloc(parenth, hndlpp, type, xtramem_sz, usrmempp) (0)
#endif

/* OCIHandleFree */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIHandleFree_func_t)(dvoid *hndlp, ub4 type);
static oci8_OCIHandleFree_func_t oci8_OCIHandleFree_func;
#define OCIHandleFree oci8_OCIHandleFree_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIHandleFree(hndlp, type) (0)
#endif

/* OCILobAssign */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobAssign_func_t)(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *src_locp, OCILobLocator **dst_locpp);
static oci8_OCILobAssign_func_t oci8_OCILobAssign_func;
#define OCILobAssign oci8_OCILobAssign_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCILobAssign(envhp, errhp, src_locp, dst_locpp) (0)
#endif

/* OCILobFileClose */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobFileClose_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep);
static oci8_OCILobFileClose_func_t oci8_OCILobFileClose_func;
#define OCILobFileClose oci8_OCILobFileClose_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCILobFileClose(svchp, errhp, filep) (0)
#endif

/* OCILobFileCloseAll */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobFileCloseAll_func_t)(OCISvcCtx *svchp, OCIError *errhp);
static oci8_OCILobFileCloseAll_func_t oci8_OCILobFileCloseAll_func;
#define OCILobFileCloseAll oci8_OCILobFileCloseAll_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCILobFileCloseAll(svchp, errhp) (0)
#endif

/* OCILobFileExists */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobFileExists_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep, boolean *flag);
static oci8_OCILobFileExists_func_t oci8_OCILobFileExists_func;
#define OCILobFileExists oci8_OCILobFileExists_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCILobFileExists(svchp, errhp, filep, flag) (0)
#endif

/* OCILobFileGetName */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobFileGetName_func_t)(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *filep, text *dir_alias, ub2 *d_length, text *filename, ub2 *f_length);
static oci8_OCILobFileGetName_func_t oci8_OCILobFileGetName_func;
#define OCILobFileGetName oci8_OCILobFileGetName_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCILobFileGetName(envhp, errhp, filep, dir_alias, d_length, filename, f_length) (0)
#endif

/* OCILobFileOpen */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobFileOpen_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep, ub1 mode);
static oci8_OCILobFileOpen_func_t oci8_OCILobFileOpen_func;
#define OCILobFileOpen oci8_OCILobFileOpen_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCILobFileOpen(svchp, errhp, filep, mode) (0)
#endif

/* OCILobFileSetName */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobFileSetName_func_t)(OCIEnv *envhp, OCIError *errhp, OCILobLocator **filepp, CONST text *dir_alias, ub2 d_length, CONST text *filename, ub2 f_length);
static oci8_OCILobFileSetName_func_t oci8_OCILobFileSetName_func;
#define OCILobFileSetName oci8_OCILobFileSetName_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCILobFileSetName(envhp, errhp, filepp, dir_alias, d_length, filename, f_length) (0)
#endif

/* OCILobLocatorIsInit */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobLocatorIsInit_func_t)(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *locp, boolean *is_initialized);
static oci8_OCILobLocatorIsInit_func_t oci8_OCILobLocatorIsInit_func;
#define OCILobLocatorIsInit oci8_OCILobLocatorIsInit_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCILobLocatorIsInit(envhp, errhp, locp, is_initialized) (0)
#endif

/* OCINumberAbs */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberAbs_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberAbs_func_t oci8_OCINumberAbs_func;
#define OCINumberAbs oci8_OCINumberAbs_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberAbs(err, number, result) (0)
#endif

/* OCINumberAdd */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberAdd_func_t)(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result);
static oci8_OCINumberAdd_func_t oci8_OCINumberAdd_func;
#define OCINumberAdd oci8_OCINumberAdd_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberAdd(err, number1, number2, result) (0)
#endif

/* OCINumberArcCos */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberArcCos_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberArcCos_func_t oci8_OCINumberArcCos_func;
#define OCINumberArcCos oci8_OCINumberArcCos_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberArcCos(err, number, result) (0)
#endif

/* OCINumberArcSin */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberArcSin_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberArcSin_func_t oci8_OCINumberArcSin_func;
#define OCINumberArcSin oci8_OCINumberArcSin_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberArcSin(err, number, result) (0)
#endif

/* OCINumberArcTan */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberArcTan_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberArcTan_func_t oci8_OCINumberArcTan_func;
#define OCINumberArcTan oci8_OCINumberArcTan_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberArcTan(err, number, result) (0)
#endif

/* OCINumberArcTan2 */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberArcTan2_func_t)(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result);
static oci8_OCINumberArcTan2_func_t oci8_OCINumberArcTan2_func;
#define OCINumberArcTan2 oci8_OCINumberArcTan2_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberArcTan2(err, number1, number2, result) (0)
#endif

/* OCINumberAssign */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberAssign_func_t)(OCIError *err, CONST OCINumber *from, OCINumber *to);
static oci8_OCINumberAssign_func_t oci8_OCINumberAssign_func;
#define OCINumberAssign oci8_OCINumberAssign_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberAssign(err, from, to) (0)
#endif

/* OCINumberCeil */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberCeil_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberCeil_func_t oci8_OCINumberCeil_func;
#define OCINumberCeil oci8_OCINumberCeil_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberCeil(err, number, result) (0)
#endif

/* OCINumberCmp */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberCmp_func_t)(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, sword *result);
static oci8_OCINumberCmp_func_t oci8_OCINumberCmp_func;
#define OCINumberCmp oci8_OCINumberCmp_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberCmp(err, number1, number2, result) (0)
#endif

/* OCINumberCos */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberCos_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberCos_func_t oci8_OCINumberCos_func;
#define OCINumberCos oci8_OCINumberCos_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberCos(err, number, result) (0)
#endif

/* OCINumberDiv */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberDiv_func_t)(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result);
static oci8_OCINumberDiv_func_t oci8_OCINumberDiv_func;
#define OCINumberDiv oci8_OCINumberDiv_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberDiv(err, number1, number2, result) (0)
#endif

/* OCINumberExp */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberExp_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberExp_func_t oci8_OCINumberExp_func;
#define OCINumberExp oci8_OCINumberExp_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberExp(err, number, result) (0)
#endif

/* OCINumberFloor */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberFloor_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberFloor_func_t oci8_OCINumberFloor_func;
#define OCINumberFloor oci8_OCINumberFloor_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberFloor(err, number, result) (0)
#endif

/* OCINumberFromInt */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberFromInt_func_t)(OCIError *err, CONST dvoid *inum, uword inum_length, uword inum_s_flag, OCINumber *number);
static oci8_OCINumberFromInt_func_t oci8_OCINumberFromInt_func;
#define OCINumberFromInt oci8_OCINumberFromInt_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberFromInt(err, inum, inum_length, inum_s_flag, number) (0)
#endif

/* OCINumberFromReal */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberFromReal_func_t)(OCIError *err, CONST dvoid *rnum, uword rnum_length, OCINumber *number);
static oci8_OCINumberFromReal_func_t oci8_OCINumberFromReal_func;
#define OCINumberFromReal oci8_OCINumberFromReal_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberFromReal(err, rnum, rnum_length, number) (0)
#endif

/* OCINumberFromText */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberFromText_func_t)(OCIError *err, CONST text *str, ub4 str_length, CONST text *fmt, ub4 fmt_length, CONST text *nls_params, ub4 nls_p_length, OCINumber *number);
static oci8_OCINumberFromText_func_t oci8_OCINumberFromText_func;
#define OCINumberFromText oci8_OCINumberFromText_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberFromText(err, str, str_length, fmt, fmt_length, nls_params, nls_p_length, number) (0)
#endif

/* OCINumberHypCos */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberHypCos_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberHypCos_func_t oci8_OCINumberHypCos_func;
#define OCINumberHypCos oci8_OCINumberHypCos_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberHypCos(err, number, result) (0)
#endif

/* OCINumberHypSin */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberHypSin_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberHypSin_func_t oci8_OCINumberHypSin_func;
#define OCINumberHypSin oci8_OCINumberHypSin_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberHypSin(err, number, result) (0)
#endif

/* OCINumberHypTan */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberHypTan_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberHypTan_func_t oci8_OCINumberHypTan_func;
#define OCINumberHypTan oci8_OCINumberHypTan_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberHypTan(err, number, result) (0)
#endif

/* OCINumberIntPower */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberIntPower_func_t)(OCIError *err, CONST OCINumber *base, CONST sword exp, OCINumber *result);
static oci8_OCINumberIntPower_func_t oci8_OCINumberIntPower_func;
#define OCINumberIntPower oci8_OCINumberIntPower_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberIntPower(err, base, exp, result) (0)
#endif

/* OCINumberIsZero */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberIsZero_func_t)(OCIError *err, CONST OCINumber *number, boolean *result);
static oci8_OCINumberIsZero_func_t oci8_OCINumberIsZero_func;
#define OCINumberIsZero oci8_OCINumberIsZero_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberIsZero(err, number, result) (0)
#endif

/* OCINumberLn */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberLn_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberLn_func_t oci8_OCINumberLn_func;
#define OCINumberLn oci8_OCINumberLn_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberLn(err, number, result) (0)
#endif

/* OCINumberLog */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberLog_func_t)(OCIError *err, CONST OCINumber *base, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberLog_func_t oci8_OCINumberLog_func;
#define OCINumberLog oci8_OCINumberLog_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberLog(err, base, number, result) (0)
#endif

/* OCINumberMod */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberMod_func_t)(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result);
static oci8_OCINumberMod_func_t oci8_OCINumberMod_func;
#define OCINumberMod oci8_OCINumberMod_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberMod(err, number1, number2, result) (0)
#endif

/* OCINumberMul */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberMul_func_t)(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result);
static oci8_OCINumberMul_func_t oci8_OCINumberMul_func;
#define OCINumberMul oci8_OCINumberMul_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberMul(err, number1, number2, result) (0)
#endif

/* OCINumberNeg */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberNeg_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberNeg_func_t oci8_OCINumberNeg_func;
#define OCINumberNeg oci8_OCINumberNeg_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberNeg(err, number, result) (0)
#endif

/* OCINumberPower */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberPower_func_t)(OCIError *err, CONST OCINumber *base, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberPower_func_t oci8_OCINumberPower_func;
#define OCINumberPower oci8_OCINumberPower_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberPower(err, base, number, result) (0)
#endif

/* OCINumberRound */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberRound_func_t)(OCIError *err, CONST OCINumber *number, sword decplace, OCINumber *result);
static oci8_OCINumberRound_func_t oci8_OCINumberRound_func;
#define OCINumberRound oci8_OCINumberRound_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberRound(err, number, decplace, result) (0)
#endif

/* OCINumberSetZero */
#if defined RUNTIME_API_CHECK
typedef void (*oci8_OCINumberSetZero_func_t)(OCIError *err, OCINumber *num);
static oci8_OCINumberSetZero_func_t oci8_OCINumberSetZero_func;
#define OCINumberSetZero oci8_OCINumberSetZero_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberSetZero(err, num) (0)
#endif

/* OCINumberSin */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberSin_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberSin_func_t oci8_OCINumberSin_func;
#define OCINumberSin oci8_OCINumberSin_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberSin(err, number, result) (0)
#endif

/* OCINumberSqrt */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberSqrt_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberSqrt_func_t oci8_OCINumberSqrt_func;
#define OCINumberSqrt oci8_OCINumberSqrt_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberSqrt(err, number, result) (0)
#endif

/* OCINumberSub */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberSub_func_t)(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result);
static oci8_OCINumberSub_func_t oci8_OCINumberSub_func;
#define OCINumberSub oci8_OCINumberSub_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberSub(err, number1, number2, result) (0)
#endif

/* OCINumberTan */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberTan_func_t)(OCIError *err, CONST OCINumber *number, OCINumber *result);
static oci8_OCINumberTan_func_t oci8_OCINumberTan_func;
#define OCINumberTan oci8_OCINumberTan_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberTan(err, number, result) (0)
#endif

/* OCINumberToInt */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberToInt_func_t)(OCIError *err, CONST OCINumber *number, uword rsl_length, uword rsl_flag, dvoid *rsl);
static oci8_OCINumberToInt_func_t oci8_OCINumberToInt_func;
#define OCINumberToInt oci8_OCINumberToInt_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberToInt(err, number, rsl_length, rsl_flag, rsl) (0)
#endif

/* OCINumberToReal */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberToReal_func_t)(OCIError *err, CONST OCINumber *number, uword rsl_length, dvoid *rsl);
static oci8_OCINumberToReal_func_t oci8_OCINumberToReal_func;
#define OCINumberToReal oci8_OCINumberToReal_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberToReal(err, number, rsl_length, rsl) (0)
#endif

/* OCINumberToText */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberToText_func_t)(OCIError *err, CONST OCINumber *number, CONST text *fmt, ub4 fmt_length, CONST text *nls_params, ub4 nls_p_length, ub4 *buf_size, text *buf);
static oci8_OCINumberToText_func_t oci8_OCINumberToText_func;
#define OCINumberToText oci8_OCINumberToText_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberToText(err, number, fmt, fmt_length, nls_params, nls_p_length, buf_size, buf) (0)
#endif

/* OCINumberTrunc */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberTrunc_func_t)(OCIError *err, CONST OCINumber *number, sword decplace, OCINumber *resulty);
static oci8_OCINumberTrunc_func_t oci8_OCINumberTrunc_func;
#define OCINumberTrunc oci8_OCINumberTrunc_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCINumberTrunc(err, number, decplace, resulty) (0)
#endif

/* OCIObjectFree */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIObjectFree_func_t)(OCIEnv *env, OCIError *err, dvoid *instance, ub2 flags);
static oci8_OCIObjectFree_func_t oci8_OCIObjectFree_func;
#define OCIObjectFree oci8_OCIObjectFree_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIObjectFree(env, err, instance, flags) (0)
#endif

/* OCIObjectGetInd */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIObjectGetInd_func_t)(OCIEnv *env, OCIError *err, dvoid *instance, dvoid **null_struct);
static oci8_OCIObjectGetInd_func_t oci8_OCIObjectGetInd_func;
#define OCIObjectGetInd oci8_OCIObjectGetInd_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIObjectGetInd(env, err, instance, null_struct) (0)
#endif

/* OCIObjectGetTypeRef */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIObjectGetTypeRef_func_t)(OCIEnv *env, OCIError *err, dvoid *instance, OCIRef *type_ref);
static oci8_OCIObjectGetTypeRef_func_t oci8_OCIObjectGetTypeRef_func;
#define OCIObjectGetTypeRef oci8_OCIObjectGetTypeRef_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIObjectGetTypeRef(env, err, instance, type_ref) (0)
#endif

/* OCIObjectNew */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIObjectNew_func_t)(OCIEnv *env, OCIError *err, CONST OCISvcCtx *svc, OCITypeCode typecode, OCIType *tdo, dvoid *table, OCIDuration duration, boolean value, dvoid **instance);
static oci8_OCIObjectNew_func_t oci8_OCIObjectNew_func;
#define OCIObjectNew oci8_OCIObjectNew_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIObjectNew(env, err, svc, typecode, tdo, table, duration, value, instance) (0)
#endif

/* OCIObjectPin */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIObjectPin_func_t)(OCIEnv *env, OCIError *err, OCIRef *object_ref, OCIComplexObject *corhdl, OCIPinOpt pin_option, OCIDuration pin_duration, OCILockOpt lock_option, dvoid **object);
static oci8_OCIObjectPin_func_t oci8_OCIObjectPin_func;
#define OCIObjectPin oci8_OCIObjectPin_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIObjectPin(env, err, object_ref, corhdl, pin_option, pin_duration, lock_option, object) (0)
#endif

/* OCIObjectUnpin */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIObjectUnpin_func_t)(OCIEnv *env, OCIError *err, dvoid *object);
static oci8_OCIObjectUnpin_func_t oci8_OCIObjectUnpin_func;
#define OCIObjectUnpin oci8_OCIObjectUnpin_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIObjectUnpin(env, err, object) (0)
#endif

/* OCIParamGet */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIParamGet_func_t)(CONST dvoid *hndlp, ub4 htype, OCIError *errhp, dvoid **parmdpp, ub4 pos);
static oci8_OCIParamGet_func_t oci8_OCIParamGet_func;
#define OCIParamGet oci8_OCIParamGet_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIParamGet(hndlp, htype, errhp, parmdpp, pos) (0)
#endif

/* OCIRawAssignBytes */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIRawAssignBytes_func_t)(OCIEnv *env, OCIError *err, CONST ub1 *rhs, ub4 rhs_len, OCIRaw **lhs);
static oci8_OCIRawAssignBytes_func_t oci8_OCIRawAssignBytes_func;
#define OCIRawAssignBytes oci8_OCIRawAssignBytes_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIRawAssignBytes(env, err, rhs, rhs_len, lhs) (0)
#endif

/* OCIRawPtr */
#if defined RUNTIME_API_CHECK
typedef ub1 * (*oci8_OCIRawPtr_func_t)(OCIEnv *env, CONST OCIRaw *raw);
static oci8_OCIRawPtr_func_t oci8_OCIRawPtr_func;
#define OCIRawPtr oci8_OCIRawPtr_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIRawPtr(env, raw) (0)
#endif

/* OCIRawSize */
#if defined RUNTIME_API_CHECK
typedef ub4 (*oci8_OCIRawSize_func_t)(OCIEnv *env, CONST OCIRaw *raw);
static oci8_OCIRawSize_func_t oci8_OCIRawSize_func;
#define OCIRawSize oci8_OCIRawSize_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIRawSize(env, raw) (0)
#endif

/* OCIServerAttach */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIServerAttach_func_t)(OCIServer *srvhp, OCIError *errhp, CONST text *dblink, sb4 dblink_len, ub4 mode);
static oci8_OCIServerAttach_func_t oci8_OCIServerAttach_func;
#define OCIServerAttach oci8_OCIServerAttach_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIServerAttach(srvhp, errhp, dblink, dblink_len, mode) (0)
#endif

/* OCIServerDetach */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIServerDetach_func_t)(OCIServer *srvhp, OCIError *errhp, ub4 mode);
static oci8_OCIServerDetach_func_t oci8_OCIServerDetach_func;
#define OCIServerDetach oci8_OCIServerDetach_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIServerDetach(srvhp, errhp, mode) (0)
#endif

/* OCIServerVersion */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIServerVersion_func_t)(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype);
static oci8_OCIServerVersion_func_t oci8_OCIServerVersion_func;
#define OCIServerVersion oci8_OCIServerVersion_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIServerVersion(hndlp, errhp, bufp, bufsz, hndltype) (0)
#endif

/* OCISessionBegin */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCISessionBegin_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCISession *usrhp, ub4 credt, ub4 mode);
static oci8_OCISessionBegin_func_t oci8_OCISessionBegin_func;
#define OCISessionBegin oci8_OCISessionBegin_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCISessionBegin(svchp, errhp, usrhp, credt, mode) (0)
#endif

/* OCISessionEnd */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCISessionEnd_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCISession *usrhp, ub4 mode);
static oci8_OCISessionEnd_func_t oci8_OCISessionEnd_func;
#define OCISessionEnd oci8_OCISessionEnd_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCISessionEnd(svchp, errhp, usrhp, mode) (0)
#endif

/* OCIStmtExecute */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIStmtExecute_func_t)(OCISvcCtx *svchp, OCIStmt *stmtp, OCIError *errhp, ub4 iters, ub4 rowoff, CONST OCISnapshot *snap_in, OCISnapshot *snap_out, ub4 mode);
static oci8_OCIStmtExecute_func_t oci8_OCIStmtExecute_func;
#define OCIStmtExecute oci8_OCIStmtExecute_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIStmtExecute(svchp, stmtp, errhp, iters, rowoff, snap_in, snap_out, mode) (0)
#endif

/* OCIStmtFetch */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIStmtFetch_func_t)(OCIStmt *stmtp, OCIError *errhp, ub4 nrows, ub2 orientation, ub4 mode);
static oci8_OCIStmtFetch_func_t oci8_OCIStmtFetch_func;
#define OCIStmtFetch oci8_OCIStmtFetch_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIStmtFetch(stmtp, errhp, nrows, orientation, mode) (0)
#endif

/* OCIStringAssignText */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIStringAssignText_func_t)(OCIEnv *env, OCIError *err, CONST text *rhs, ub4 rhs_len, OCIString **lhs);
static oci8_OCIStringAssignText_func_t oci8_OCIStringAssignText_func;
#define OCIStringAssignText oci8_OCIStringAssignText_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIStringAssignText(env, err, rhs, rhs_len, lhs) (0)
#endif

/* OCIStringPtr */
#if defined RUNTIME_API_CHECK
typedef text * (*oci8_OCIStringPtr_func_t)(OCIEnv *env, CONST OCIString *vs);
static oci8_OCIStringPtr_func_t oci8_OCIStringPtr_func;
#define OCIStringPtr oci8_OCIStringPtr_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIStringPtr(env, vs) (0)
#endif

/* OCIStringSize */
#if defined RUNTIME_API_CHECK
typedef ub4 (*oci8_OCIStringSize_func_t)(OCIEnv *env, CONST OCIString *vs);
static oci8_OCIStringSize_func_t oci8_OCIStringSize_func;
#define OCIStringSize oci8_OCIStringSize_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCIStringSize(env, vs) (0)
#endif

/* OCITransCommit */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCITransCommit_func_t)(OCISvcCtx *svchp, OCIError *errhp, ub4 flags);
static oci8_OCITransCommit_func_t oci8_OCITransCommit_func;
#define OCITransCommit oci8_OCITransCommit_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCITransCommit(svchp, errhp, flags) (0)
#endif

/* OCITransRollback */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCITransRollback_func_t)(OCISvcCtx *svchp, OCIError *errhp, ub4 flags);
static oci8_OCITransRollback_func_t oci8_OCITransRollback_func;
#define OCITransRollback oci8_OCITransRollback_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCITransRollback(svchp, errhp, flags) (0)
#endif

/* OCITypeTypeCode */
#if defined RUNTIME_API_CHECK
typedef OCITypeCode (*oci8_OCITypeTypeCode_func_t)(OCIEnv *env, OCIError *err, CONST OCIType *tdo);
static oci8_OCITypeTypeCode_func_t oci8_OCITypeTypeCode_func;
#define OCITypeTypeCode oci8_OCITypeTypeCode_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_0
#define OCITypeTypeCode(env, err, tdo) (0)
#endif

/* OCIEnvCreate */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIEnvCreate_func_t)(OCIEnv **envp, ub4 mode, dvoid *ctxp, dvoid *(*malocfp)(dvoid *ctxp, size_t size), dvoid *(*ralocfp)(dvoid *ctxp, dvoid *memptr, size_t newsize), void   (*mfreefp)(dvoid *ctxp, dvoid *memptr), size_t xtramem_sz, dvoid **usrmempp);
static oci8_OCIEnvCreate_func_t oci8_OCIEnvCreate_func;
#define OCIEnvCreate oci8_OCIEnvCreate_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCIEnvCreate(envp, mode, ctxp, malocfp, ralocfp, mfreefp, xtramem_sz, usrmempp) (0)
#endif

/* OCILobClose */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobClose_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp);
static oci8_OCILobClose_func_t oci8_OCILobClose_func;
#define OCILobClose oci8_OCILobClose_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCILobClose(svchp, errhp, locp) (0)
#endif

/* OCILobCreateTemporary */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobCreateTemporary_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub2 csid, ub1 csfrm, ub1 lobtype, boolean cache, OCIDuration duration);
static oci8_OCILobCreateTemporary_func_t oci8_OCILobCreateTemporary_func;
#define OCILobCreateTemporary oci8_OCILobCreateTemporary_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCILobCreateTemporary(svchp, errhp, locp, csid, csfrm, lobtype, cache, duration) (0)
#endif

/* OCILobFreeTemporary */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobFreeTemporary_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp);
static oci8_OCILobFreeTemporary_func_t oci8_OCILobFreeTemporary_func;
#define OCILobFreeTemporary oci8_OCILobFreeTemporary_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCILobFreeTemporary(svchp, errhp, locp) (0)
#endif

/* OCILobGetChunkSize */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobGetChunkSize_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub4 *chunksizep);
static oci8_OCILobGetChunkSize_func_t oci8_OCILobGetChunkSize_func;
#define OCILobGetChunkSize oci8_OCILobGetChunkSize_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCILobGetChunkSize(svchp, errhp, locp, chunksizep) (0)
#endif

/* OCILobIsTemporary */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobIsTemporary_func_t)(OCIEnv *envp, OCIError *errhp, OCILobLocator *locp, boolean *is_temporary);
static oci8_OCILobIsTemporary_func_t oci8_OCILobIsTemporary_func;
#define OCILobIsTemporary oci8_OCILobIsTemporary_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCILobIsTemporary(envp, errhp, locp, is_temporary) (0)
#endif

/* OCILobLocatorAssign */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobLocatorAssign_func_t)(OCISvcCtx *svchp, OCIError *errhp, CONST OCILobLocator *src_locp, OCILobLocator **dst_locpp);
static oci8_OCILobLocatorAssign_func_t oci8_OCILobLocatorAssign_func;
#define OCILobLocatorAssign oci8_OCILobLocatorAssign_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCILobLocatorAssign(svchp, errhp, src_locp, dst_locpp) (0)
#endif

/* OCILobOpen */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobOpen_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub1 mode);
static oci8_OCILobOpen_func_t oci8_OCILobOpen_func;
#define OCILobOpen oci8_OCILobOpen_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCILobOpen(svchp, errhp, locp, mode) (0)
#endif

/* OCIMessageGet */
#if defined RUNTIME_API_CHECK
typedef OraText * (*oci8_OCIMessageGet_func_t)(OCIMsg *msgh, ub4 msgno, OraText *msgbuf, size_t buflen);
static oci8_OCIMessageGet_func_t oci8_OCIMessageGet_func;
#define OCIMessageGet oci8_OCIMessageGet_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCIMessageGet(msgh, msgno, msgbuf, buflen) (0)
#endif

/* OCIMessageOpen */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIMessageOpen_func_t)(dvoid *envhp, OCIError *errhp, OCIMsg **msghp, CONST OraText *product, CONST OraText *facility, OCIDuration dur);
static oci8_OCIMessageOpen_func_t oci8_OCIMessageOpen_func;
#define OCIMessageOpen oci8_OCIMessageOpen_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCIMessageOpen(envhp, errhp, msghp, product, facility, dur) (0)
#endif

/* OCINumberIsInt */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberIsInt_func_t)(OCIError *err, CONST OCINumber *number, boolean *result);
static oci8_OCINumberIsInt_func_t oci8_OCINumberIsInt_func;
#define OCINumberIsInt oci8_OCINumberIsInt_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCINumberIsInt(err, number, result) (0)
#endif

/* OCINumberPrec */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberPrec_func_t)(OCIError *err, CONST OCINumber *number, eword nDigs, OCINumber *result);
static oci8_OCINumberPrec_func_t oci8_OCINumberPrec_func;
#define OCINumberPrec oci8_OCINumberPrec_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCINumberPrec(err, number, nDigs, result) (0)
#endif

/* OCINumberSetPi */
#if defined RUNTIME_API_CHECK
typedef void (*oci8_OCINumberSetPi_func_t)(OCIError *err, OCINumber *num);
static oci8_OCINumberSetPi_func_t oci8_OCINumberSetPi_func;
#define OCINumberSetPi oci8_OCINumberSetPi_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCINumberSetPi(err, num) (0)
#endif

/* OCINumberShift */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberShift_func_t)(OCIError *err, CONST OCINumber *number, CONST sword nDig, OCINumber *result);
static oci8_OCINumberShift_func_t oci8_OCINumberShift_func;
#define OCINumberShift oci8_OCINumberShift_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCINumberShift(err, number, nDig, result) (0)
#endif

/* OCINumberSign */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINumberSign_func_t)(OCIError *err, CONST OCINumber *number, sword *result);
static oci8_OCINumberSign_func_t oci8_OCINumberSign_func;
#define OCINumberSign oci8_OCINumberSign_func
#elif ORACLE_CLIENT_VERSION < ORAVER_8_1
#define OCINumberSign(err, number, result) (0)
#endif

/* OCIConnectionPoolCreate */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIConnectionPoolCreate_func_t)(OCIEnv *envhp, OCIError *errhp, OCICPool *poolhp, OraText **poolName, sb4 *poolNameLen, const OraText *dblink, sb4 dblinkLen, ub4 connMin, ub4 connMax, ub4 connIncr, const OraText *poolUserName, sb4 poolUserLen, const OraText *poolPassword, sb4 poolPassLen, ub4 mode);
static oci8_OCIConnectionPoolCreate_func_t oci8_OCIConnectionPoolCreate_func;
#define OCIConnectionPoolCreate oci8_OCIConnectionPoolCreate_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIConnectionPoolCreate(envhp, errhp, poolhp, poolName, poolNameLen, dblink, dblinkLen, connMin, connMax, connIncr, poolUserName, poolUserLen, poolPassword, poolPassLen, mode) (0)
#endif

/* OCIConnectionPoolDestroy */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIConnectionPoolDestroy_func_t)(OCICPool *poolhp, OCIError *errhp, ub4 mode);
static oci8_OCIConnectionPoolDestroy_func_t oci8_OCIConnectionPoolDestroy_func;
#define OCIConnectionPoolDestroy oci8_OCIConnectionPoolDestroy_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIConnectionPoolDestroy(poolhp, errhp, mode) (0)
#endif

/* OCIDateTimeConstruct */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDateTimeConstruct_func_t)(dvoid  *hndl, OCIError *err, OCIDateTime *datetime, sb2 yr, ub1 mnth, ub1 dy, ub1 hr, ub1 mm, ub1 ss, ub4 fsec, OraText *timezone, size_t timezone_length);
static oci8_OCIDateTimeConstruct_func_t oci8_OCIDateTimeConstruct_func;
#define OCIDateTimeConstruct oci8_OCIDateTimeConstruct_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIDateTimeConstruct(hndl, err, datetime, yr, mnth, dy, hr, mm, ss, fsec, timezone, timezone_length) (0)
#endif

/* OCIDateTimeGetDate */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDateTimeGetDate_func_t)(dvoid *hndl, OCIError *err, CONST OCIDateTime *date, sb2 *yr, ub1 *mnth, ub1 *dy);
static oci8_OCIDateTimeGetDate_func_t oci8_OCIDateTimeGetDate_func;
#define OCIDateTimeGetDate oci8_OCIDateTimeGetDate_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIDateTimeGetDate(hndl, err, date, yr, mnth, dy) (0)
#endif

/* OCIDateTimeGetTime */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDateTimeGetTime_func_t)(dvoid *hndl, OCIError *err, OCIDateTime *datetime, ub1 *hr, ub1 *mm, ub1 *ss, ub4 *fsec);
static oci8_OCIDateTimeGetTime_func_t oci8_OCIDateTimeGetTime_func;
#define OCIDateTimeGetTime oci8_OCIDateTimeGetTime_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIDateTimeGetTime(hndl, err, datetime, hr, mm, ss, fsec) (0)
#endif

/* OCIDateTimeGetTimeZoneOffset */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIDateTimeGetTimeZoneOffset_func_t)(dvoid *hndl, OCIError *err, CONST OCIDateTime *datetime, sb1 *hr, sb1 *mm);
static oci8_OCIDateTimeGetTimeZoneOffset_func_t oci8_OCIDateTimeGetTimeZoneOffset_func;
#define OCIDateTimeGetTimeZoneOffset oci8_OCIDateTimeGetTimeZoneOffset_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIDateTimeGetTimeZoneOffset(hndl, err, datetime, hr, mm) (0)
#endif

/* OCIIntervalGetDaySecond */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIIntervalGetDaySecond_func_t)(dvoid *hndl, OCIError *err, sb4 *dy, sb4 *hr, sb4 *mm, sb4 *ss, sb4 *fsec, CONST OCIInterval *result);
static oci8_OCIIntervalGetDaySecond_func_t oci8_OCIIntervalGetDaySecond_func;
#define OCIIntervalGetDaySecond oci8_OCIIntervalGetDaySecond_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIIntervalGetDaySecond(hndl, err, dy, hr, mm, ss, fsec, result) (0)
#endif

/* OCIIntervalGetYearMonth */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIIntervalGetYearMonth_func_t)(dvoid *hndl, OCIError *err, sb4 *yr, sb4 *mnth, CONST OCIInterval *result);
static oci8_OCIIntervalGetYearMonth_func_t oci8_OCIIntervalGetYearMonth_func;
#define OCIIntervalGetYearMonth oci8_OCIIntervalGetYearMonth_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIIntervalGetYearMonth(hndl, err, yr, mnth, result) (0)
#endif

/* OCIIntervalSetDaySecond */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIIntervalSetDaySecond_func_t)(dvoid *hndl, OCIError *err, sb4 dy, sb4 hr, sb4 mm, sb4 ss, sb4 fsec, OCIInterval *result);
static oci8_OCIIntervalSetDaySecond_func_t oci8_OCIIntervalSetDaySecond_func;
#define OCIIntervalSetDaySecond oci8_OCIIntervalSetDaySecond_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIIntervalSetDaySecond(hndl, err, dy, hr, mm, ss, fsec, result) (0)
#endif

/* OCIIntervalSetYearMonth */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIIntervalSetYearMonth_func_t)(dvoid *hndl, OCIError *err, sb4 yr, sb4 mnth, OCIInterval *result);
static oci8_OCIIntervalSetYearMonth_func_t oci8_OCIIntervalSetYearMonth_func;
#define OCIIntervalSetYearMonth oci8_OCIIntervalSetYearMonth_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIIntervalSetYearMonth(hndl, err, yr, mnth, result) (0)
#endif

/* OCIRowidToChar */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIRowidToChar_func_t)(OCIRowid *rowidDesc, OraText *outbfp, ub2 *outbflp, OCIError *errhp);
static oci8_OCIRowidToChar_func_t oci8_OCIRowidToChar_func;
#define OCIRowidToChar oci8_OCIRowidToChar_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIRowidToChar(rowidDesc, outbfp, outbflp, errhp) (0)
#endif

/* OCIServerRelease */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIServerRelease_func_t)(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype, ub4 *version);
static oci8_OCIServerRelease_func_t oci8_OCIServerRelease_func;
#define OCIServerRelease oci8_OCIServerRelease_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_0
#define OCIServerRelease(hndlp, errhp, bufp, bufsz, hndltype, version) (0)
#endif

/* OCINlsCharSetIdToName */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCINlsCharSetIdToName_func_t)(dvoid *envhp, oratext *buf, size_t buflen, ub2 id);
static oci8_OCINlsCharSetIdToName_func_t oci8_OCINlsCharSetIdToName_func;
#define OCINlsCharSetIdToName oci8_OCINlsCharSetIdToName_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_2
#define OCINlsCharSetIdToName(envhp, buf, buflen, id) (0)
#endif

/* OCINlsCharSetNameToId */
#if defined RUNTIME_API_CHECK
typedef ub2 (*oci8_OCINlsCharSetNameToId_func_t)(dvoid *envhp, const oratext *name);
static oci8_OCINlsCharSetNameToId_func_t oci8_OCINlsCharSetNameToId_func;
#define OCINlsCharSetNameToId oci8_OCINlsCharSetNameToId_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_2
#define OCINlsCharSetNameToId(envhp, name) (0)
#endif

/* OCIStmtPrepare2 */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIStmtPrepare2_func_t)(OCISvcCtx *svchp, OCIStmt **stmtp, OCIError *errhp, const OraText *stmt, ub4 stmt_len, const OraText *key, ub4 key_len, ub4 language, ub4 mode);
static oci8_OCIStmtPrepare2_func_t oci8_OCIStmtPrepare2_func;
#define OCIStmtPrepare2 oci8_OCIStmtPrepare2_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_2
#define OCIStmtPrepare2(svchp, stmtp, errhp, stmt, stmt_len, key, key_len, language, mode) (0)
#endif

/* OCIStmtRelease */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIStmtRelease_func_t)(OCIStmt *stmtp, OCIError *errhp, const OraText *key, ub4 key_len, ub4 mode);
static oci8_OCIStmtRelease_func_t oci8_OCIStmtRelease_func;
#define OCIStmtRelease oci8_OCIStmtRelease_func
#elif ORACLE_CLIENT_VERSION < ORAVER_9_2
#define OCIStmtRelease(stmtp, errhp, key, key_len, mode) (0)
#endif

/* OCILobGetLength2 */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobGetLength2_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *lenp);
static oci8_OCILobGetLength2_func_t oci8_OCILobGetLength2_func;
#define OCILobGetLength2 oci8_OCILobGetLength2_func
#elif ORACLE_CLIENT_VERSION < ORAVER_10_1
#define OCILobGetLength2(svchp, errhp, locp, lenp) (0)
#endif

/* OCILobRead2 */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobRead2_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *byte_amtp, oraub8 *char_amtp, oraub8 offset, dvoid *bufp, oraub8 bufl, ub1 piece, dvoid *ctxp, OCICallbackLobRead2 cbfp, ub2 csid, ub1 csfrm);
static oci8_OCILobRead2_func_t oci8_OCILobRead2_func;
#define OCILobRead2 oci8_OCILobRead2_func
#elif ORACLE_CLIENT_VERSION < ORAVER_10_1
#define OCILobRead2(svchp, errhp, locp, byte_amtp, char_amtp, offset, bufp, bufl, piece, ctxp, cbfp, csid, csfrm) (0)
#endif

/* OCILobTrim2 */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobTrim2_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 newlen);
static oci8_OCILobTrim2_func_t oci8_OCILobTrim2_func;
#define OCILobTrim2 oci8_OCILobTrim2_func
#elif ORACLE_CLIENT_VERSION < ORAVER_10_1
#define OCILobTrim2(svchp, errhp, locp, newlen) (0)
#endif

/* OCILobWrite2 */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCILobWrite2_func_t)(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *byte_amtp, oraub8 *char_amtp, oraub8 offset, dvoid *bufp, oraub8 buflen, ub1 piece, dvoid *ctxp, OCICallbackLobWrite2 cbfp, ub2 csid, ub1 csfrm);
static oci8_OCILobWrite2_func_t oci8_OCILobWrite2_func;
#define OCILobWrite2 oci8_OCILobWrite2_func
#elif ORACLE_CLIENT_VERSION < ORAVER_10_1
#define OCILobWrite2(svchp, errhp, locp, byte_amtp, char_amtp, offset, bufp, buflen, piece, ctxp, cbfp, csid, csfrm) (0)
#endif

/* OCIClientVersion */
#if defined RUNTIME_API_CHECK
typedef void (*oci8_OCIClientVersion_func_t)(sword *major_version, sword *minor_version, sword *update_num, sword *patch_num, sword *port_update_num);
static oci8_OCIClientVersion_func_t oci8_OCIClientVersion_func;
#define OCIClientVersion oci8_OCIClientVersion_func
#elif ORACLE_CLIENT_VERSION < ORAVER_10_2
#define OCIClientVersion(major_version, minor_version, update_num, patch_num, port_update_num) (0)
#endif

/* OCIPing */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIPing_func_t)(OCISvcCtx *svchp, OCIError *errhp, ub4 mode);
static oci8_OCIPing_func_t oci8_OCIPing_func;
#define OCIPing oci8_OCIPing_func
#elif ORACLE_CLIENT_VERSION < ORAVER_10_2
#define OCIPing(svchp, errhp, mode) (0)
#endif

/* OCIServerRelease2 */
#if defined RUNTIME_API_CHECK
typedef sword (*oci8_OCIServerRelease2_func_t)(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype, ub4 *version, ub4 mode);
static oci8_OCIServerRelease2_func_t oci8_OCIServerRelease2_func;
#define OCIServerRelease2 oci8_OCIServerRelease2_func
#elif ORACLE_CLIENT_VERSION < ORAVER_18
#define OCIServerRelease2(hndlp, errhp, bufp, bufsz, hndltype, version, mode) (0)
#endif

/*
 * OCIAttrGet
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIAttrGet;
#endif

sword oci8_OCIAttrGet(CONST dvoid *trgthndlp, ub4 trghndltyp, dvoid *attributep, ub4 *sizep, ub4 attrtype, OCIError *errhp, const char *file, int line)
{
    if (have_OCIAttrGet) {
        return OCIAttrGet(trgthndlp, trghndltyp, attributep, sizep, attrtype, errhp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIAttrGet");
    }
}

/*
 * OCIAttrGet_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    CONST dvoid *trgthndlp;
    ub4 trghndltyp;
    dvoid *attributep;
    ub4 *sizep;
    ub4 attrtype;
    OCIError *errhp;
} oci8_OCIAttrGet_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCIAttrGet_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCIAttrGet_cb(void *user_data)
{
    oci8_OCIAttrGet_data_t *data = (oci8_OCIAttrGet_data_t *)user_data;
    data->rv = OCIAttrGet(data->trgthndlp, data->trghndltyp, data->attributep, data->sizep, data->attrtype, data->errhp);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCIAttrGet_cb NULL
#endif

sword oci8_OCIAttrGet_nb(oci8_svcctx_t *svcctx, CONST dvoid *trgthndlp, ub4 trghndltyp, dvoid *attributep, ub4 *sizep, ub4 attrtype, OCIError *errhp, const char *file, int line)
{
    if (have_OCIAttrGet_nb) {
        oci8_OCIAttrGet_data_t data;
        data.svcctx = svcctx;
        data.trgthndlp = trgthndlp;
        data.trghndltyp = trghndltyp;
        data.attributep = attributep;
        data.sizep = sizep;
        data.attrtype = attrtype;
        data.errhp = errhp;
        oci8_call_without_gvl(svcctx, oci8_OCIAttrGet_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIAttrGet_nb");
    }
}

/*
 * OCIAttrSet
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIAttrSet;
#endif

sword oci8_OCIAttrSet(dvoid *trgthndlp, ub4 trghndltyp, dvoid *attributep, ub4 size, ub4 attrtype, OCIError *errhp, const char *file, int line)
{
    if (have_OCIAttrSet) {
        return OCIAttrSet(trgthndlp, trghndltyp, attributep, size, attrtype, errhp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIAttrSet");
    }
}

/*
 * OCIBindArrayOfStruct
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIBindArrayOfStruct;
#endif

sword oci8_OCIBindArrayOfStruct(OCIBind *bindp, OCIError *errhp, ub4 pvskip, ub4 indskip, ub4 alskip, ub4 rcskip, const char *file, int line)
{
    if (have_OCIBindArrayOfStruct) {
        return OCIBindArrayOfStruct(bindp, errhp, pvskip, indskip, alskip, rcskip);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIBindArrayOfStruct");
    }
}

/*
 * OCIBindByName
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIBindByName;
#endif

sword oci8_OCIBindByName(OCIStmt *stmtp, OCIBind **bindp, OCIError *errhp, CONST text *placeholder, sb4 placeh_len, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *alenp, ub2 *rcodep, ub4 maxarr_len, ub4 *curelep, ub4 mode, const char *file, int line)
{
    if (have_OCIBindByName) {
        return OCIBindByName(stmtp, bindp, errhp, placeholder, placeh_len, valuep, value_sz, dty, indp, alenp, rcodep, maxarr_len, curelep, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIBindByName");
    }
}

/*
 * OCIBindByPos
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIBindByPos;
#endif

sword oci8_OCIBindByPos(OCIStmt *stmtp, OCIBind **bindp, OCIError *errhp, ub4 position, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *alenp, ub2 *rcodep, ub4 maxarr_len, ub4 *curelep, ub4 mode, const char *file, int line)
{
    if (have_OCIBindByPos) {
        return OCIBindByPos(stmtp, bindp, errhp, position, valuep, value_sz, dty, indp, alenp, rcodep, maxarr_len, curelep, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIBindByPos");
    }
}

/*
 * OCIBindDynamic
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIBindDynamic;
#endif

sword oci8_OCIBindDynamic(OCIBind *bindp, OCIError *errhp, void  *ictxp, OCICallbackInBind icbfp, void  *octxp, OCICallbackOutBind ocbfp, const char *file, int line)
{
    if (have_OCIBindDynamic) {
        return OCIBindDynamic(bindp, errhp, ictxp, icbfp, octxp, ocbfp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIBindDynamic");
    }
}

/*
 * OCIBindObject
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIBindObject;
#endif

sword oci8_OCIBindObject(OCIBind *bindp, OCIError *errhp, CONST OCIType *type, dvoid **pgvpp, ub4 *pvszsp, dvoid **indpp, ub4 *indszp, const char *file, int line)
{
    if (have_OCIBindObject) {
        return OCIBindObject(bindp, errhp, type, pgvpp, pvszsp, indpp, indszp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIBindObject");
    }
}

/*
 * OCIBreak
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIBreak;
#endif

sword oci8_OCIBreak(dvoid *hndlp, OCIError *errhp, const char *file, int line)
{
    if (have_OCIBreak) {
        return OCIBreak(hndlp, errhp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIBreak");
    }
}

/*
 * OCICollAppend
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCICollAppend;
#endif

sword oci8_OCICollAppend(OCIEnv *env, OCIError *err, CONST dvoid *elem, CONST dvoid *elemind, OCIColl *coll, const char *file, int line)
{
    if (have_OCICollAppend) {
        return OCICollAppend(env, err, elem, elemind, coll);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCICollAppend");
    }
}

/*
 * OCICollAssignElem
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCICollAssignElem;
#endif

sword oci8_OCICollAssignElem(OCIEnv *env, OCIError *err, sb4 index, CONST dvoid *elem, CONST dvoid *elemind, OCIColl *coll, const char *file, int line)
{
    if (have_OCICollAssignElem) {
        return OCICollAssignElem(env, err, index, elem, elemind, coll);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCICollAssignElem");
    }
}

/*
 * OCICollGetElem
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCICollGetElem;
#endif

sword oci8_OCICollGetElem(OCIEnv *env, OCIError *err, CONST OCIColl *coll, sb4 index, boolean *exists, dvoid **elem, dvoid **elemind, const char *file, int line)
{
    if (have_OCICollGetElem) {
        return OCICollGetElem(env, err, coll, index, exists, elem, elemind);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCICollGetElem");
    }
}

/*
 * OCICollSize
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCICollSize;
#endif

sword oci8_OCICollSize(OCIEnv *env, OCIError *err, CONST OCIColl *coll, sb4 *size, const char *file, int line)
{
    if (have_OCICollSize) {
        return OCICollSize(env, err, coll, size);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCICollSize");
    }
}

/*
 * OCICollTrim
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCICollTrim;
#endif

sword oci8_OCICollTrim(OCIEnv *env, OCIError *err, sb4 trim_num, OCIColl *coll, const char *file, int line)
{
    if (have_OCICollTrim) {
        return OCICollTrim(env, err, trim_num, coll);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCICollTrim");
    }
}

/*
 * OCIDefineArrayOfStruct
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDefineArrayOfStruct;
#endif

sword oci8_OCIDefineArrayOfStruct(OCIDefine *defnp, OCIError *errhp, ub4 pvskip, ub4 indskip, ub4 rlskip, ub4 rcskip, const char *file, int line)
{
    if (have_OCIDefineArrayOfStruct) {
        return OCIDefineArrayOfStruct(defnp, errhp, pvskip, indskip, rlskip, rcskip);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDefineArrayOfStruct");
    }
}

/*
 * OCIDefineByPos
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDefineByPos;
#endif

sword oci8_OCIDefineByPos(OCIStmt *stmtp, OCIDefine **defnp, OCIError *errhp, ub4 position, dvoid *valuep, sb4 value_sz, ub2 dty, dvoid *indp, ub2 *rlenp, ub2 *rcodep, ub4 mode, const char *file, int line)
{
    if (have_OCIDefineByPos) {
        return OCIDefineByPos(stmtp, defnp, errhp, position, valuep, value_sz, dty, indp, rlenp, rcodep, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDefineByPos");
    }
}

/*
 * OCIDefineDynamic
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDefineDynamic;
#endif

sword oci8_OCIDefineDynamic(OCIDefine *defnp, OCIError *errhp, dvoid *octxp, OCICallbackDefine ocbfp, const char *file, int line)
{
    if (have_OCIDefineDynamic) {
        return OCIDefineDynamic(defnp, errhp, octxp, ocbfp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDefineDynamic");
    }
}

/*
 * OCIDefineObject
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDefineObject;
#endif

sword oci8_OCIDefineObject(OCIDefine *defnp, OCIError *errhp, CONST OCIType *type, dvoid **pgvpp, ub4 *pvszsp, dvoid **indpp, ub4 *indszp, const char *file, int line)
{
    if (have_OCIDefineObject) {
        return OCIDefineObject(defnp, errhp, type, pgvpp, pvszsp, indpp, indszp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDefineObject");
    }
}

/*
 * OCIDescribeAny_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    dvoid *objptr;
    ub4 objnm_len;
    ub1 objptr_typ;
    ub1 info_level;
    ub1 objtyp;
    OCIDescribe *dschp;
} oci8_OCIDescribeAny_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCIDescribeAny_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCIDescribeAny_cb(void *user_data)
{
    oci8_OCIDescribeAny_data_t *data = (oci8_OCIDescribeAny_data_t *)user_data;
    data->rv = OCIDescribeAny(data->svchp, data->errhp, data->objptr, data->objnm_len, data->objptr_typ, data->info_level, data->objtyp, data->dschp);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCIDescribeAny_cb NULL
#endif

sword oci8_OCIDescribeAny_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, dvoid *objptr, ub4 objnm_len, ub1 objptr_typ, ub1 info_level, ub1 objtyp, OCIDescribe *dschp, const char *file, int line)
{
    if (have_OCIDescribeAny_nb) {
        oci8_OCIDescribeAny_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.objptr = objptr;
        data.objnm_len = objnm_len;
        data.objptr_typ = objptr_typ;
        data.info_level = info_level;
        data.objtyp = objtyp;
        data.dschp = dschp;
        oci8_call_without_gvl(svcctx, oci8_OCIDescribeAny_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDescribeAny_nb");
    }
}

/*
 * OCIDescriptorAlloc
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDescriptorAlloc;
#endif

sword oci8_OCIDescriptorAlloc(CONST dvoid *parenth, dvoid **descpp, ub4 type, size_t xtramem_sz, dvoid **usrmempp, const char *file, int line)
{
    if (have_OCIDescriptorAlloc) {
        return OCIDescriptorAlloc(parenth, descpp, type, xtramem_sz, usrmempp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDescriptorAlloc");
    }
}

/*
 * OCIDescriptorFree
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDescriptorFree;
#endif

sword oci8_OCIDescriptorFree(dvoid *descp, ub4 type, const char *file, int line)
{
    if (have_OCIDescriptorFree) {
        return OCIDescriptorFree(descp, type);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDescriptorFree");
    }
}

/*
 * OCIErrorGet
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIErrorGet;
#endif

sword oci8_OCIErrorGet(dvoid *hndlp, ub4 recordno, text *sqlstate, sb4 *errcodep, text *bufp, ub4 bufsiz, ub4 type, const char *file, int line)
{
    if (have_OCIErrorGet) {
        return OCIErrorGet(hndlp, recordno, sqlstate, errcodep, bufp, bufsiz, type);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIErrorGet");
    }
}

/*
 * OCIHandleAlloc
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIHandleAlloc;
#endif

sword oci8_OCIHandleAlloc(CONST dvoid *parenth, dvoid **hndlpp, ub4 type, size_t xtramem_sz, dvoid **usrmempp, const char *file, int line)
{
    if (have_OCIHandleAlloc) {
        return OCIHandleAlloc(parenth, hndlpp, type, xtramem_sz, usrmempp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIHandleAlloc");
    }
}

/*
 * OCIHandleFree
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIHandleFree;
#endif

sword oci8_OCIHandleFree(dvoid *hndlp, ub4 type, const char *file, int line)
{
    if (have_OCIHandleFree) {
        return OCIHandleFree(hndlp, type);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIHandleFree");
    }
}

/*
 * OCILobAssign
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCILobAssign;
#endif

sword oci8_OCILobAssign(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *src_locp, OCILobLocator **dst_locpp, const char *file, int line)
{
    if (have_OCILobAssign) {
        return OCILobAssign(envhp, errhp, src_locp, dst_locpp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobAssign");
    }
}

/*
 * OCILobFileClose_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *filep;
} oci8_OCILobFileClose_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobFileClose_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCILobFileClose_cb(void *user_data)
{
    oci8_OCILobFileClose_data_t *data = (oci8_OCILobFileClose_data_t *)user_data;
    data->rv = OCILobFileClose(data->svchp, data->errhp, data->filep);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobFileClose_cb NULL
#endif

sword oci8_OCILobFileClose_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep, const char *file, int line)
{
    if (have_OCILobFileClose_nb) {
        oci8_OCILobFileClose_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.filep = filep;
        oci8_call_without_gvl(svcctx, oci8_OCILobFileClose_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobFileClose_nb");
    }
}

/*
 * OCILobFileCloseAll_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
} oci8_OCILobFileCloseAll_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobFileCloseAll_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCILobFileCloseAll_cb(void *user_data)
{
    oci8_OCILobFileCloseAll_data_t *data = (oci8_OCILobFileCloseAll_data_t *)user_data;
    data->rv = OCILobFileCloseAll(data->svchp, data->errhp);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobFileCloseAll_cb NULL
#endif

sword oci8_OCILobFileCloseAll_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, const char *file, int line)
{
    if (have_OCILobFileCloseAll_nb) {
        oci8_OCILobFileCloseAll_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        oci8_call_without_gvl(svcctx, oci8_OCILobFileCloseAll_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobFileCloseAll_nb");
    }
}

/*
 * OCILobFileExists_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *filep;
    boolean *flag;
} oci8_OCILobFileExists_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobFileExists_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCILobFileExists_cb(void *user_data)
{
    oci8_OCILobFileExists_data_t *data = (oci8_OCILobFileExists_data_t *)user_data;
    data->rv = OCILobFileExists(data->svchp, data->errhp, data->filep, data->flag);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobFileExists_cb NULL
#endif

sword oci8_OCILobFileExists_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep, boolean *flag, const char *file, int line)
{
    if (have_OCILobFileExists_nb) {
        oci8_OCILobFileExists_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.filep = filep;
        data.flag = flag;
        oci8_call_without_gvl(svcctx, oci8_OCILobFileExists_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobFileExists_nb");
    }
}

/*
 * OCILobFileGetName
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCILobFileGetName;
#endif

sword oci8_OCILobFileGetName(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *filep, text *dir_alias, ub2 *d_length, text *filename, ub2 *f_length, const char *file, int line)
{
    if (have_OCILobFileGetName) {
        return OCILobFileGetName(envhp, errhp, filep, dir_alias, d_length, filename, f_length);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobFileGetName");
    }
}

/*
 * OCILobFileOpen_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *filep;
    ub1 mode;
} oci8_OCILobFileOpen_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobFileOpen_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCILobFileOpen_cb(void *user_data)
{
    oci8_OCILobFileOpen_data_t *data = (oci8_OCILobFileOpen_data_t *)user_data;
    data->rv = OCILobFileOpen(data->svchp, data->errhp, data->filep, data->mode);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobFileOpen_cb NULL
#endif

sword oci8_OCILobFileOpen_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *filep, ub1 mode, const char *file, int line)
{
    if (have_OCILobFileOpen_nb) {
        oci8_OCILobFileOpen_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.filep = filep;
        data.mode = mode;
        oci8_call_without_gvl(svcctx, oci8_OCILobFileOpen_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobFileOpen_nb");
    }
}

/*
 * OCILobFileSetName
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCILobFileSetName;
#endif

sword oci8_OCILobFileSetName(OCIEnv *envhp, OCIError *errhp, OCILobLocator **filepp, CONST text *dir_alias, ub2 d_length, CONST text *filename, ub2 f_length, const char *file, int line)
{
    if (have_OCILobFileSetName) {
        return OCILobFileSetName(envhp, errhp, filepp, dir_alias, d_length, filename, f_length);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobFileSetName");
    }
}

/*
 * OCILobLocatorIsInit
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCILobLocatorIsInit;
#endif

sword oci8_OCILobLocatorIsInit(OCIEnv *envhp, OCIError *errhp, CONST OCILobLocator *locp, boolean *is_initialized, const char *file, int line)
{
    if (have_OCILobLocatorIsInit) {
        return OCILobLocatorIsInit(envhp, errhp, locp, is_initialized);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobLocatorIsInit");
    }
}

/*
 * OCINumberAbs
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberAbs;
#endif

sword oci8_OCINumberAbs(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberAbs) {
        return OCINumberAbs(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberAbs");
    }
}

/*
 * OCINumberAdd
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberAdd;
#endif

sword oci8_OCINumberAdd(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberAdd) {
        return OCINumberAdd(err, number1, number2, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberAdd");
    }
}

/*
 * OCINumberArcCos
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberArcCos;
#endif

sword oci8_OCINumberArcCos(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberArcCos) {
        return OCINumberArcCos(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberArcCos");
    }
}

/*
 * OCINumberArcSin
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberArcSin;
#endif

sword oci8_OCINumberArcSin(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberArcSin) {
        return OCINumberArcSin(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberArcSin");
    }
}

/*
 * OCINumberArcTan
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberArcTan;
#endif

sword oci8_OCINumberArcTan(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberArcTan) {
        return OCINumberArcTan(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberArcTan");
    }
}

/*
 * OCINumberArcTan2
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberArcTan2;
#endif

sword oci8_OCINumberArcTan2(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberArcTan2) {
        return OCINumberArcTan2(err, number1, number2, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberArcTan2");
    }
}

/*
 * OCINumberAssign
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberAssign;
#endif

sword oci8_OCINumberAssign(OCIError *err, CONST OCINumber *from, OCINumber *to, const char *file, int line)
{
    if (have_OCINumberAssign) {
        return OCINumberAssign(err, from, to);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberAssign");
    }
}

/*
 * OCINumberCeil
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberCeil;
#endif

sword oci8_OCINumberCeil(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberCeil) {
        return OCINumberCeil(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberCeil");
    }
}

/*
 * OCINumberCmp
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberCmp;
#endif

sword oci8_OCINumberCmp(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, sword *result, const char *file, int line)
{
    if (have_OCINumberCmp) {
        return OCINumberCmp(err, number1, number2, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberCmp");
    }
}

/*
 * OCINumberCos
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberCos;
#endif

sword oci8_OCINumberCos(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberCos) {
        return OCINumberCos(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberCos");
    }
}

/*
 * OCINumberDiv
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberDiv;
#endif

sword oci8_OCINumberDiv(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberDiv) {
        return OCINumberDiv(err, number1, number2, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberDiv");
    }
}

/*
 * OCINumberExp
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberExp;
#endif

sword oci8_OCINumberExp(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberExp) {
        return OCINumberExp(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberExp");
    }
}

/*
 * OCINumberFloor
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberFloor;
#endif

sword oci8_OCINumberFloor(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberFloor) {
        return OCINumberFloor(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberFloor");
    }
}

/*
 * OCINumberFromInt
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberFromInt;
#endif

sword oci8_OCINumberFromInt(OCIError *err, CONST dvoid *inum, uword inum_length, uword inum_s_flag, OCINumber *number, const char *file, int line)
{
    if (have_OCINumberFromInt) {
        return OCINumberFromInt(err, inum, inum_length, inum_s_flag, number);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberFromInt");
    }
}

/*
 * OCINumberFromReal
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberFromReal;
#endif

sword oci8_OCINumberFromReal(OCIError *err, CONST dvoid *rnum, uword rnum_length, OCINumber *number, const char *file, int line)
{
    if (have_OCINumberFromReal) {
        return OCINumberFromReal(err, rnum, rnum_length, number);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberFromReal");
    }
}

/*
 * OCINumberFromText
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberFromText;
#endif

sword oci8_OCINumberFromText(OCIError *err, CONST text *str, ub4 str_length, CONST text *fmt, ub4 fmt_length, CONST text *nls_params, ub4 nls_p_length, OCINumber *number, const char *file, int line)
{
    if (have_OCINumberFromText) {
        return OCINumberFromText(err, str, str_length, fmt, fmt_length, nls_params, nls_p_length, number);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberFromText");
    }
}

/*
 * OCINumberHypCos
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberHypCos;
#endif

sword oci8_OCINumberHypCos(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberHypCos) {
        return OCINumberHypCos(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberHypCos");
    }
}

/*
 * OCINumberHypSin
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberHypSin;
#endif

sword oci8_OCINumberHypSin(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberHypSin) {
        return OCINumberHypSin(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberHypSin");
    }
}

/*
 * OCINumberHypTan
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberHypTan;
#endif

sword oci8_OCINumberHypTan(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberHypTan) {
        return OCINumberHypTan(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberHypTan");
    }
}

/*
 * OCINumberIntPower
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberIntPower;
#endif

sword oci8_OCINumberIntPower(OCIError *err, CONST OCINumber *base, CONST sword exp, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberIntPower) {
        return OCINumberIntPower(err, base, exp, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberIntPower");
    }
}

/*
 * OCINumberIsZero
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberIsZero;
#endif

sword oci8_OCINumberIsZero(OCIError *err, CONST OCINumber *number, boolean *result, const char *file, int line)
{
    if (have_OCINumberIsZero) {
        return OCINumberIsZero(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberIsZero");
    }
}

/*
 * OCINumberLn
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberLn;
#endif

sword oci8_OCINumberLn(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberLn) {
        return OCINumberLn(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberLn");
    }
}

/*
 * OCINumberLog
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberLog;
#endif

sword oci8_OCINumberLog(OCIError *err, CONST OCINumber *base, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberLog) {
        return OCINumberLog(err, base, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberLog");
    }
}

/*
 * OCINumberMod
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberMod;
#endif

sword oci8_OCINumberMod(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberMod) {
        return OCINumberMod(err, number1, number2, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberMod");
    }
}

/*
 * OCINumberMul
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberMul;
#endif

sword oci8_OCINumberMul(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberMul) {
        return OCINumberMul(err, number1, number2, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberMul");
    }
}

/*
 * OCINumberNeg
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberNeg;
#endif

sword oci8_OCINumberNeg(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberNeg) {
        return OCINumberNeg(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberNeg");
    }
}

/*
 * OCINumberPower
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberPower;
#endif

sword oci8_OCINumberPower(OCIError *err, CONST OCINumber *base, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberPower) {
        return OCINumberPower(err, base, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberPower");
    }
}

/*
 * OCINumberRound
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberRound;
#endif

sword oci8_OCINumberRound(OCIError *err, CONST OCINumber *number, sword decplace, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberRound) {
        return OCINumberRound(err, number, decplace, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberRound");
    }
}

/*
 * OCINumberSetZero
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberSetZero;
#endif

void oci8_OCINumberSetZero(OCIError *err, OCINumber *num, const char *file, int line)
{
    if (have_OCINumberSetZero) {
        OCINumberSetZero(err, num);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberSetZero");
    }
}

/*
 * OCINumberSin
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberSin;
#endif

sword oci8_OCINumberSin(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberSin) {
        return OCINumberSin(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberSin");
    }
}

/*
 * OCINumberSqrt
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberSqrt;
#endif

sword oci8_OCINumberSqrt(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberSqrt) {
        return OCINumberSqrt(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberSqrt");
    }
}

/*
 * OCINumberSub
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberSub;
#endif

sword oci8_OCINumberSub(OCIError *err, CONST OCINumber *number1, CONST OCINumber *number2, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberSub) {
        return OCINumberSub(err, number1, number2, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberSub");
    }
}

/*
 * OCINumberTan
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberTan;
#endif

sword oci8_OCINumberTan(OCIError *err, CONST OCINumber *number, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberTan) {
        return OCINumberTan(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberTan");
    }
}

/*
 * OCINumberToInt
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberToInt;
#endif

sword oci8_OCINumberToInt(OCIError *err, CONST OCINumber *number, uword rsl_length, uword rsl_flag, dvoid *rsl, const char *file, int line)
{
    if (have_OCINumberToInt) {
        return OCINumberToInt(err, number, rsl_length, rsl_flag, rsl);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberToInt");
    }
}

/*
 * OCINumberToReal
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberToReal;
#endif

sword oci8_OCINumberToReal(OCIError *err, CONST OCINumber *number, uword rsl_length, dvoid *rsl, const char *file, int line)
{
    if (have_OCINumberToReal) {
        return OCINumberToReal(err, number, rsl_length, rsl);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberToReal");
    }
}

/*
 * OCINumberToText
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberToText;
#endif

sword oci8_OCINumberToText(OCIError *err, CONST OCINumber *number, CONST text *fmt, ub4 fmt_length, CONST text *nls_params, ub4 nls_p_length, ub4 *buf_size, text *buf, const char *file, int line)
{
    if (have_OCINumberToText) {
        return OCINumberToText(err, number, fmt, fmt_length, nls_params, nls_p_length, buf_size, buf);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberToText");
    }
}

/*
 * OCINumberTrunc
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberTrunc;
#endif

sword oci8_OCINumberTrunc(OCIError *err, CONST OCINumber *number, sword decplace, OCINumber *resulty, const char *file, int line)
{
    if (have_OCINumberTrunc) {
        return OCINumberTrunc(err, number, decplace, resulty);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberTrunc");
    }
}

/*
 * OCIObjectFree
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIObjectFree;
#endif

sword oci8_OCIObjectFree(OCIEnv *env, OCIError *err, dvoid *instance, ub2 flags, const char *file, int line)
{
    if (have_OCIObjectFree) {
        return OCIObjectFree(env, err, instance, flags);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIObjectFree");
    }
}

/*
 * OCIObjectGetInd
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIObjectGetInd;
#endif

sword oci8_OCIObjectGetInd(OCIEnv *env, OCIError *err, dvoid *instance, dvoid **null_struct, const char *file, int line)
{
    if (have_OCIObjectGetInd) {
        return OCIObjectGetInd(env, err, instance, null_struct);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIObjectGetInd");
    }
}

/*
 * OCIObjectGetTypeRef
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIObjectGetTypeRef;
#endif

sword oci8_OCIObjectGetTypeRef(OCIEnv *env, OCIError *err, dvoid *instance, OCIRef *type_ref, const char *file, int line)
{
    if (have_OCIObjectGetTypeRef) {
        return OCIObjectGetTypeRef(env, err, instance, type_ref);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIObjectGetTypeRef");
    }
}

/*
 * OCIObjectNew
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIObjectNew;
#endif

sword oci8_OCIObjectNew(OCIEnv *env, OCIError *err, CONST OCISvcCtx *svc, OCITypeCode typecode, OCIType *tdo, dvoid *table, OCIDuration duration, boolean value, dvoid **instance, const char *file, int line)
{
    if (have_OCIObjectNew) {
        return OCIObjectNew(env, err, svc, typecode, tdo, table, duration, value, instance);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIObjectNew");
    }
}

/*
 * OCIObjectPin_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCIEnv *env;
    OCIError *err;
    OCIRef *object_ref;
    OCIComplexObject *corhdl;
    OCIPinOpt pin_option;
    OCIDuration pin_duration;
    OCILockOpt lock_option;
    dvoid **object;
} oci8_OCIObjectPin_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCIObjectPin_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCIObjectPin_cb(void *user_data)
{
    oci8_OCIObjectPin_data_t *data = (oci8_OCIObjectPin_data_t *)user_data;
    data->rv = OCIObjectPin(data->env, data->err, data->object_ref, data->corhdl, data->pin_option, data->pin_duration, data->lock_option, data->object);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCIObjectPin_cb NULL
#endif

sword oci8_OCIObjectPin_nb(oci8_svcctx_t *svcctx, OCIEnv *env, OCIError *err, OCIRef *object_ref, OCIComplexObject *corhdl, OCIPinOpt pin_option, OCIDuration pin_duration, OCILockOpt lock_option, dvoid **object, const char *file, int line)
{
    if (have_OCIObjectPin_nb) {
        oci8_OCIObjectPin_data_t data;
        data.svcctx = svcctx;
        data.env = env;
        data.err = err;
        data.object_ref = object_ref;
        data.corhdl = corhdl;
        data.pin_option = pin_option;
        data.pin_duration = pin_duration;
        data.lock_option = lock_option;
        data.object = object;
        oci8_call_without_gvl(svcctx, oci8_OCIObjectPin_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIObjectPin_nb");
    }
}

/*
 * OCIObjectUnpin
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIObjectUnpin;
#endif

sword oci8_OCIObjectUnpin(OCIEnv *env, OCIError *err, dvoid *object, const char *file, int line)
{
    if (have_OCIObjectUnpin) {
        return OCIObjectUnpin(env, err, object);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIObjectUnpin");
    }
}

/*
 * OCIParamGet
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIParamGet;
#endif

sword oci8_OCIParamGet(CONST dvoid *hndlp, ub4 htype, OCIError *errhp, dvoid **parmdpp, ub4 pos, const char *file, int line)
{
    if (have_OCIParamGet) {
        return OCIParamGet(hndlp, htype, errhp, parmdpp, pos);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIParamGet");
    }
}

/*
 * OCIRawAssignBytes
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIRawAssignBytes;
#endif

sword oci8_OCIRawAssignBytes(OCIEnv *env, OCIError *err, CONST ub1 *rhs, ub4 rhs_len, OCIRaw **lhs, const char *file, int line)
{
    if (have_OCIRawAssignBytes) {
        return OCIRawAssignBytes(env, err, rhs, rhs_len, lhs);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIRawAssignBytes");
    }
}

/*
 * OCIRawPtr
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIRawPtr;
#endif

ub1 * oci8_OCIRawPtr(OCIEnv *env, CONST OCIRaw *raw, const char *file, int line)
{
    if (have_OCIRawPtr) {
        return OCIRawPtr(env, raw);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIRawPtr");
    }
}

/*
 * OCIRawSize
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIRawSize;
#endif

ub4 oci8_OCIRawSize(OCIEnv *env, CONST OCIRaw *raw, const char *file, int line)
{
    if (have_OCIRawSize) {
        return OCIRawSize(env, raw);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIRawSize");
    }
}

/*
 * OCIServerAttach_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCIServer *srvhp;
    OCIError *errhp;
    CONST text *dblink;
    sb4 dblink_len;
    ub4 mode;
} oci8_OCIServerAttach_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCIServerAttach_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCIServerAttach_cb(void *user_data)
{
    oci8_OCIServerAttach_data_t *data = (oci8_OCIServerAttach_data_t *)user_data;
    data->rv = OCIServerAttach(data->srvhp, data->errhp, data->dblink, data->dblink_len, data->mode);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCIServerAttach_cb NULL
#endif

sword oci8_OCIServerAttach_nb(oci8_svcctx_t *svcctx, OCIServer *srvhp, OCIError *errhp, CONST text *dblink, sb4 dblink_len, ub4 mode, const char *file, int line)
{
    if (have_OCIServerAttach_nb) {
        oci8_OCIServerAttach_data_t data;
        data.svcctx = svcctx;
        data.srvhp = srvhp;
        data.errhp = errhp;
        data.dblink = dblink;
        data.dblink_len = dblink_len;
        data.mode = mode;
        oci8_call_without_gvl(svcctx, oci8_OCIServerAttach_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIServerAttach_nb");
    }
}

/*
 * OCIServerDetach
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIServerDetach;
#endif

sword oci8_OCIServerDetach(OCIServer *srvhp, OCIError *errhp, ub4 mode, const char *file, int line)
{
    if (have_OCIServerDetach) {
        return OCIServerDetach(srvhp, errhp, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIServerDetach");
    }
}

/*
 * OCIServerVersion
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIServerVersion;
#endif

sword oci8_OCIServerVersion(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype, const char *file, int line)
{
    if (have_OCIServerVersion) {
        return OCIServerVersion(hndlp, errhp, bufp, bufsz, hndltype);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIServerVersion");
    }
}

/*
 * OCISessionBegin_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCISession *usrhp;
    ub4 credt;
    ub4 mode;
} oci8_OCISessionBegin_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCISessionBegin_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCISessionBegin_cb(void *user_data)
{
    oci8_OCISessionBegin_data_t *data = (oci8_OCISessionBegin_data_t *)user_data;
    data->rv = OCISessionBegin(data->svchp, data->errhp, data->usrhp, data->credt, data->mode);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCISessionBegin_cb NULL
#endif

sword oci8_OCISessionBegin_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCISession *usrhp, ub4 credt, ub4 mode, const char *file, int line)
{
    if (have_OCISessionBegin_nb) {
        oci8_OCISessionBegin_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.usrhp = usrhp;
        data.credt = credt;
        data.mode = mode;
        oci8_call_without_gvl(svcctx, oci8_OCISessionBegin_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCISessionBegin_nb");
    }
}

/*
 * OCISessionEnd
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCISessionEnd;
#endif

sword oci8_OCISessionEnd(OCISvcCtx *svchp, OCIError *errhp, OCISession *usrhp, ub4 mode, const char *file, int line)
{
    if (have_OCISessionEnd) {
        return OCISessionEnd(svchp, errhp, usrhp, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCISessionEnd");
    }
}

/*
 * OCIStmtExecute_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIStmt *stmtp;
    OCIError *errhp;
    ub4 iters;
    ub4 rowoff;
    CONST OCISnapshot *snap_in;
    OCISnapshot *snap_out;
    ub4 mode;
} oci8_OCIStmtExecute_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCIStmtExecute_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCIStmtExecute_cb(void *user_data)
{
    oci8_OCIStmtExecute_data_t *data = (oci8_OCIStmtExecute_data_t *)user_data;
    data->rv = OCIStmtExecute(data->svchp, data->stmtp, data->errhp, data->iters, data->rowoff, data->snap_in, data->snap_out, data->mode);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCIStmtExecute_cb NULL
#endif

sword oci8_OCIStmtExecute_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIStmt *stmtp, OCIError *errhp, ub4 iters, ub4 rowoff, CONST OCISnapshot *snap_in, OCISnapshot *snap_out, ub4 mode, const char *file, int line)
{
    if (have_OCIStmtExecute_nb) {
        oci8_OCIStmtExecute_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.stmtp = stmtp;
        data.errhp = errhp;
        data.iters = iters;
        data.rowoff = rowoff;
        data.snap_in = snap_in;
        data.snap_out = snap_out;
        data.mode = mode;
        oci8_call_without_gvl(svcctx, oci8_OCIStmtExecute_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIStmtExecute_nb");
    }
}

/*
 * OCIStmtFetch_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCIStmt *stmtp;
    OCIError *errhp;
    ub4 nrows;
    ub2 orientation;
    ub4 mode;
} oci8_OCIStmtFetch_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCIStmtFetch_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCIStmtFetch_cb(void *user_data)
{
    oci8_OCIStmtFetch_data_t *data = (oci8_OCIStmtFetch_data_t *)user_data;
    data->rv = OCIStmtFetch(data->stmtp, data->errhp, data->nrows, data->orientation, data->mode);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCIStmtFetch_cb NULL
#endif

sword oci8_OCIStmtFetch_nb(oci8_svcctx_t *svcctx, OCIStmt *stmtp, OCIError *errhp, ub4 nrows, ub2 orientation, ub4 mode, const char *file, int line)
{
    if (have_OCIStmtFetch_nb) {
        oci8_OCIStmtFetch_data_t data;
        data.svcctx = svcctx;
        data.stmtp = stmtp;
        data.errhp = errhp;
        data.nrows = nrows;
        data.orientation = orientation;
        data.mode = mode;
        oci8_call_without_gvl(svcctx, oci8_OCIStmtFetch_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIStmtFetch_nb");
    }
}

/*
 * OCIStringAssignText
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIStringAssignText;
#endif

sword oci8_OCIStringAssignText(OCIEnv *env, OCIError *err, CONST text *rhs, ub4 rhs_len, OCIString **lhs, const char *file, int line)
{
    if (have_OCIStringAssignText) {
        return OCIStringAssignText(env, err, rhs, rhs_len, lhs);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIStringAssignText");
    }
}

/*
 * OCIStringPtr
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIStringPtr;
#endif

text * oci8_OCIStringPtr(OCIEnv *env, CONST OCIString *vs, const char *file, int line)
{
    if (have_OCIStringPtr) {
        return OCIStringPtr(env, vs);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIStringPtr");
    }
}

/*
 * OCIStringSize
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIStringSize;
#endif

ub4 oci8_OCIStringSize(OCIEnv *env, CONST OCIString *vs, const char *file, int line)
{
    if (have_OCIStringSize) {
        return OCIStringSize(env, vs);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIStringSize");
    }
}

/*
 * OCITransCommit_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    ub4 flags;
} oci8_OCITransCommit_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCITransCommit_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCITransCommit_cb(void *user_data)
{
    oci8_OCITransCommit_data_t *data = (oci8_OCITransCommit_data_t *)user_data;
    data->rv = OCITransCommit(data->svchp, data->errhp, data->flags);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCITransCommit_cb NULL
#endif

sword oci8_OCITransCommit_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, ub4 flags, const char *file, int line)
{
    if (have_OCITransCommit_nb) {
        oci8_OCITransCommit_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.flags = flags;
        oci8_call_without_gvl(svcctx, oci8_OCITransCommit_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCITransCommit_nb");
    }
}

/*
 * OCITransRollback
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCITransRollback;
#endif

sword oci8_OCITransRollback(OCISvcCtx *svchp, OCIError *errhp, ub4 flags, const char *file, int line)
{
    if (have_OCITransRollback) {
        return OCITransRollback(svchp, errhp, flags);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCITransRollback");
    }
}

/*
 * OCITransRollback_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    ub4 flags;
} oci8_OCITransRollback_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCITransRollback_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_0
static void *oci8_OCITransRollback_cb(void *user_data)
{
    oci8_OCITransRollback_data_t *data = (oci8_OCITransRollback_data_t *)user_data;
    data->rv = OCITransRollback(data->svchp, data->errhp, data->flags);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCITransRollback_cb NULL
#endif

sword oci8_OCITransRollback_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, ub4 flags, const char *file, int line)
{
    if (have_OCITransRollback_nb) {
        oci8_OCITransRollback_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.flags = flags;
        oci8_call_without_gvl(svcctx, oci8_OCITransRollback_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCITransRollback_nb");
    }
}

/*
 * OCITypeTypeCode
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCITypeTypeCode;
#endif

OCITypeCode oci8_OCITypeTypeCode(OCIEnv *env, OCIError *err, CONST OCIType *tdo, const char *file, int line)
{
    if (have_OCITypeTypeCode) {
        return OCITypeTypeCode(env, err, tdo);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCITypeTypeCode");
    }
}

/*
 * OCIEnvCreate
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIEnvCreate;
#endif

sword oci8_OCIEnvCreate(OCIEnv **envp, ub4 mode, dvoid *ctxp, dvoid *(*malocfp)(dvoid *ctxp, size_t size), dvoid *(*ralocfp)(dvoid *ctxp, dvoid *memptr, size_t newsize), void   (*mfreefp)(dvoid *ctxp, dvoid *memptr), size_t xtramem_sz, dvoid **usrmempp, const char *file, int line)
{
    if (have_OCIEnvCreate) {
        return OCIEnvCreate(envp, mode, ctxp, malocfp, ralocfp, mfreefp, xtramem_sz, usrmempp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIEnvCreate");
    }
}

/*
 * OCILobClose_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *locp;
} oci8_OCILobClose_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobClose_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_1
static void *oci8_OCILobClose_cb(void *user_data)
{
    oci8_OCILobClose_data_t *data = (oci8_OCILobClose_data_t *)user_data;
    data->rv = OCILobClose(data->svchp, data->errhp, data->locp);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobClose_cb NULL
#endif

sword oci8_OCILobClose_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, const char *file, int line)
{
    if (have_OCILobClose_nb) {
        oci8_OCILobClose_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.locp = locp;
        oci8_call_without_gvl(svcctx, oci8_OCILobClose_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobClose_nb");
    }
}

/*
 * OCILobCreateTemporary_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *locp;
    ub2 csid;
    ub1 csfrm;
    ub1 lobtype;
    boolean cache;
    OCIDuration duration;
} oci8_OCILobCreateTemporary_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobCreateTemporary_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_1
static void *oci8_OCILobCreateTemporary_cb(void *user_data)
{
    oci8_OCILobCreateTemporary_data_t *data = (oci8_OCILobCreateTemporary_data_t *)user_data;
    data->rv = OCILobCreateTemporary(data->svchp, data->errhp, data->locp, data->csid, data->csfrm, data->lobtype, data->cache, data->duration);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobCreateTemporary_cb NULL
#endif

sword oci8_OCILobCreateTemporary_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub2 csid, ub1 csfrm, ub1 lobtype, boolean cache, OCIDuration duration, const char *file, int line)
{
    if (have_OCILobCreateTemporary_nb) {
        oci8_OCILobCreateTemporary_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.locp = locp;
        data.csid = csid;
        data.csfrm = csfrm;
        data.lobtype = lobtype;
        data.cache = cache;
        data.duration = duration;
        oci8_call_without_gvl(svcctx, oci8_OCILobCreateTemporary_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobCreateTemporary_nb");
    }
}

/*
 * OCILobFreeTemporary
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCILobFreeTemporary;
#endif

sword oci8_OCILobFreeTemporary(OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, const char *file, int line)
{
    if (have_OCILobFreeTemporary) {
        return OCILobFreeTemporary(svchp, errhp, locp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobFreeTemporary");
    }
}

/*
 * OCILobGetChunkSize_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *locp;
    ub4 *chunksizep;
} oci8_OCILobGetChunkSize_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobGetChunkSize_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_1
static void *oci8_OCILobGetChunkSize_cb(void *user_data)
{
    oci8_OCILobGetChunkSize_data_t *data = (oci8_OCILobGetChunkSize_data_t *)user_data;
    data->rv = OCILobGetChunkSize(data->svchp, data->errhp, data->locp, data->chunksizep);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobGetChunkSize_cb NULL
#endif

sword oci8_OCILobGetChunkSize_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub4 *chunksizep, const char *file, int line)
{
    if (have_OCILobGetChunkSize_nb) {
        oci8_OCILobGetChunkSize_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.locp = locp;
        data.chunksizep = chunksizep;
        oci8_call_without_gvl(svcctx, oci8_OCILobGetChunkSize_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobGetChunkSize_nb");
    }
}

/*
 * OCILobIsTemporary
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCILobIsTemporary;
#endif

sword oci8_OCILobIsTemporary(OCIEnv *envp, OCIError *errhp, OCILobLocator *locp, boolean *is_temporary, const char *file, int line)
{
    if (have_OCILobIsTemporary) {
        return OCILobIsTemporary(envp, errhp, locp, is_temporary);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobIsTemporary");
    }
}

/*
 * OCILobLocatorAssign_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    CONST OCILobLocator *src_locp;
    OCILobLocator **dst_locpp;
} oci8_OCILobLocatorAssign_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobLocatorAssign_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_1
static void *oci8_OCILobLocatorAssign_cb(void *user_data)
{
    oci8_OCILobLocatorAssign_data_t *data = (oci8_OCILobLocatorAssign_data_t *)user_data;
    data->rv = OCILobLocatorAssign(data->svchp, data->errhp, data->src_locp, data->dst_locpp);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobLocatorAssign_cb NULL
#endif

sword oci8_OCILobLocatorAssign_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, CONST OCILobLocator *src_locp, OCILobLocator **dst_locpp, const char *file, int line)
{
    if (have_OCILobLocatorAssign_nb) {
        oci8_OCILobLocatorAssign_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.src_locp = src_locp;
        data.dst_locpp = dst_locpp;
        oci8_call_without_gvl(svcctx, oci8_OCILobLocatorAssign_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobLocatorAssign_nb");
    }
}

/*
 * OCILobOpen_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *locp;
    ub1 mode;
} oci8_OCILobOpen_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobOpen_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_8_1
static void *oci8_OCILobOpen_cb(void *user_data)
{
    oci8_OCILobOpen_data_t *data = (oci8_OCILobOpen_data_t *)user_data;
    data->rv = OCILobOpen(data->svchp, data->errhp, data->locp, data->mode);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobOpen_cb NULL
#endif

sword oci8_OCILobOpen_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, ub1 mode, const char *file, int line)
{
    if (have_OCILobOpen_nb) {
        oci8_OCILobOpen_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.locp = locp;
        data.mode = mode;
        oci8_call_without_gvl(svcctx, oci8_OCILobOpen_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobOpen_nb");
    }
}

/*
 * OCIMessageGet
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIMessageGet;
#endif

OraText * oci8_OCIMessageGet(OCIMsg *msgh, ub4 msgno, OraText *msgbuf, size_t buflen, const char *file, int line)
{
    if (have_OCIMessageGet) {
        return OCIMessageGet(msgh, msgno, msgbuf, buflen);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIMessageGet");
    }
}

/*
 * OCIMessageOpen
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIMessageOpen;
#endif

sword oci8_OCIMessageOpen(dvoid *envhp, OCIError *errhp, OCIMsg **msghp, CONST OraText *product, CONST OraText *facility, OCIDuration dur, const char *file, int line)
{
    if (have_OCIMessageOpen) {
        return OCIMessageOpen(envhp, errhp, msghp, product, facility, dur);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIMessageOpen");
    }
}

/*
 * OCINumberIsInt
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberIsInt;
#endif

sword oci8_OCINumberIsInt(OCIError *err, CONST OCINumber *number, boolean *result, const char *file, int line)
{
    if (have_OCINumberIsInt) {
        return OCINumberIsInt(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberIsInt");
    }
}

/*
 * OCINumberPrec
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberPrec;
#endif

sword oci8_OCINumberPrec(OCIError *err, CONST OCINumber *number, eword nDigs, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberPrec) {
        return OCINumberPrec(err, number, nDigs, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberPrec");
    }
}

/*
 * OCINumberSetPi
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberSetPi;
#endif

void oci8_OCINumberSetPi(OCIError *err, OCINumber *num, const char *file, int line)
{
    if (have_OCINumberSetPi) {
        OCINumberSetPi(err, num);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberSetPi");
    }
}

/*
 * OCINumberShift
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberShift;
#endif

sword oci8_OCINumberShift(OCIError *err, CONST OCINumber *number, CONST sword nDig, OCINumber *result, const char *file, int line)
{
    if (have_OCINumberShift) {
        return OCINumberShift(err, number, nDig, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberShift");
    }
}

/*
 * OCINumberSign
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINumberSign;
#endif

sword oci8_OCINumberSign(OCIError *err, CONST OCINumber *number, sword *result, const char *file, int line)
{
    if (have_OCINumberSign) {
        return OCINumberSign(err, number, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINumberSign");
    }
}

/*
 * OCIConnectionPoolCreate
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIConnectionPoolCreate;
#endif

sword oci8_OCIConnectionPoolCreate(OCIEnv *envhp, OCIError *errhp, OCICPool *poolhp, OraText **poolName, sb4 *poolNameLen, const OraText *dblink, sb4 dblinkLen, ub4 connMin, ub4 connMax, ub4 connIncr, const OraText *poolUserName, sb4 poolUserLen, const OraText *poolPassword, sb4 poolPassLen, ub4 mode, const char *file, int line)
{
    if (have_OCIConnectionPoolCreate) {
        return OCIConnectionPoolCreate(envhp, errhp, poolhp, poolName, poolNameLen, dblink, dblinkLen, connMin, connMax, connIncr, poolUserName, poolUserLen, poolPassword, poolPassLen, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIConnectionPoolCreate");
    }
}

/*
 * OCIConnectionPoolDestroy
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIConnectionPoolDestroy;
#endif

sword oci8_OCIConnectionPoolDestroy(OCICPool *poolhp, OCIError *errhp, ub4 mode, const char *file, int line)
{
    if (have_OCIConnectionPoolDestroy) {
        return OCIConnectionPoolDestroy(poolhp, errhp, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIConnectionPoolDestroy");
    }
}

/*
 * OCIDateTimeConstruct
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDateTimeConstruct;
#endif

sword oci8_OCIDateTimeConstruct(dvoid  *hndl, OCIError *err, OCIDateTime *datetime, sb2 yr, ub1 mnth, ub1 dy, ub1 hr, ub1 mm, ub1 ss, ub4 fsec, OraText *timezone, size_t timezone_length, const char *file, int line)
{
    if (have_OCIDateTimeConstruct) {
        return OCIDateTimeConstruct(hndl, err, datetime, yr, mnth, dy, hr, mm, ss, fsec, timezone, timezone_length);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDateTimeConstruct");
    }
}

/*
 * OCIDateTimeGetDate
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDateTimeGetDate;
#endif

sword oci8_OCIDateTimeGetDate(dvoid *hndl, OCIError *err, CONST OCIDateTime *date, sb2 *yr, ub1 *mnth, ub1 *dy, const char *file, int line)
{
    if (have_OCIDateTimeGetDate) {
        return OCIDateTimeGetDate(hndl, err, date, yr, mnth, dy);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDateTimeGetDate");
    }
}

/*
 * OCIDateTimeGetTime
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDateTimeGetTime;
#endif

sword oci8_OCIDateTimeGetTime(dvoid *hndl, OCIError *err, OCIDateTime *datetime, ub1 *hr, ub1 *mm, ub1 *ss, ub4 *fsec, const char *file, int line)
{
    if (have_OCIDateTimeGetTime) {
        return OCIDateTimeGetTime(hndl, err, datetime, hr, mm, ss, fsec);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDateTimeGetTime");
    }
}

/*
 * OCIDateTimeGetTimeZoneOffset
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIDateTimeGetTimeZoneOffset;
#endif

sword oci8_OCIDateTimeGetTimeZoneOffset(dvoid *hndl, OCIError *err, CONST OCIDateTime *datetime, sb1 *hr, sb1 *mm, const char *file, int line)
{
    if (have_OCIDateTimeGetTimeZoneOffset) {
        return OCIDateTimeGetTimeZoneOffset(hndl, err, datetime, hr, mm);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIDateTimeGetTimeZoneOffset");
    }
}

/*
 * OCIIntervalGetDaySecond
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIIntervalGetDaySecond;
#endif

sword oci8_OCIIntervalGetDaySecond(dvoid *hndl, OCIError *err, sb4 *dy, sb4 *hr, sb4 *mm, sb4 *ss, sb4 *fsec, CONST OCIInterval *result, const char *file, int line)
{
    if (have_OCIIntervalGetDaySecond) {
        return OCIIntervalGetDaySecond(hndl, err, dy, hr, mm, ss, fsec, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIIntervalGetDaySecond");
    }
}

/*
 * OCIIntervalGetYearMonth
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIIntervalGetYearMonth;
#endif

sword oci8_OCIIntervalGetYearMonth(dvoid *hndl, OCIError *err, sb4 *yr, sb4 *mnth, CONST OCIInterval *result, const char *file, int line)
{
    if (have_OCIIntervalGetYearMonth) {
        return OCIIntervalGetYearMonth(hndl, err, yr, mnth, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIIntervalGetYearMonth");
    }
}

/*
 * OCIIntervalSetDaySecond
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIIntervalSetDaySecond;
#endif

sword oci8_OCIIntervalSetDaySecond(dvoid *hndl, OCIError *err, sb4 dy, sb4 hr, sb4 mm, sb4 ss, sb4 fsec, OCIInterval *result, const char *file, int line)
{
    if (have_OCIIntervalSetDaySecond) {
        return OCIIntervalSetDaySecond(hndl, err, dy, hr, mm, ss, fsec, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIIntervalSetDaySecond");
    }
}

/*
 * OCIIntervalSetYearMonth
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIIntervalSetYearMonth;
#endif

sword oci8_OCIIntervalSetYearMonth(dvoid *hndl, OCIError *err, sb4 yr, sb4 mnth, OCIInterval *result, const char *file, int line)
{
    if (have_OCIIntervalSetYearMonth) {
        return OCIIntervalSetYearMonth(hndl, err, yr, mnth, result);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIIntervalSetYearMonth");
    }
}

/*
 * OCIRowidToChar
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIRowidToChar;
#endif

sword oci8_OCIRowidToChar(OCIRowid *rowidDesc, OraText *outbfp, ub2 *outbflp, OCIError *errhp, const char *file, int line)
{
    if (have_OCIRowidToChar) {
        return OCIRowidToChar(rowidDesc, outbfp, outbflp, errhp);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIRowidToChar");
    }
}

/*
 * OCIServerRelease
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIServerRelease;
#endif

sword oci8_OCIServerRelease(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype, ub4 *version, const char *file, int line)
{
    if (have_OCIServerRelease) {
        return OCIServerRelease(hndlp, errhp, bufp, bufsz, hndltype, version);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIServerRelease");
    }
}

/*
 * OCINlsCharSetIdToName
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINlsCharSetIdToName;
#endif

sword oci8_OCINlsCharSetIdToName(dvoid *envhp, oratext *buf, size_t buflen, ub2 id, const char *file, int line)
{
    if (have_OCINlsCharSetIdToName) {
        return OCINlsCharSetIdToName(envhp, buf, buflen, id);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINlsCharSetIdToName");
    }
}

/*
 * OCINlsCharSetNameToId
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCINlsCharSetNameToId;
#endif

ub2 oci8_OCINlsCharSetNameToId(dvoid *envhp, const oratext *name, const char *file, int line)
{
    if (have_OCINlsCharSetNameToId) {
        return OCINlsCharSetNameToId(envhp, name);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCINlsCharSetNameToId");
    }
}

/*
 * OCIStmtPrepare2
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIStmtPrepare2;
#endif

sword oci8_OCIStmtPrepare2(OCISvcCtx *svchp, OCIStmt **stmtp, OCIError *errhp, const OraText *stmt, ub4 stmt_len, const OraText *key, ub4 key_len, ub4 language, ub4 mode, const char *file, int line)
{
    if (have_OCIStmtPrepare2) {
        return OCIStmtPrepare2(svchp, stmtp, errhp, stmt, stmt_len, key, key_len, language, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIStmtPrepare2");
    }
}

/*
 * OCIStmtRelease
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIStmtRelease;
#endif

sword oci8_OCIStmtRelease(OCIStmt *stmtp, OCIError *errhp, const OraText *key, ub4 key_len, ub4 mode, const char *file, int line)
{
    if (have_OCIStmtRelease) {
        return OCIStmtRelease(stmtp, errhp, key, key_len, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIStmtRelease");
    }
}

/*
 * OCILobGetLength2_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *locp;
    oraub8 *lenp;
} oci8_OCILobGetLength2_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobGetLength2_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_10_1
static void *oci8_OCILobGetLength2_cb(void *user_data)
{
    oci8_OCILobGetLength2_data_t *data = (oci8_OCILobGetLength2_data_t *)user_data;
    data->rv = OCILobGetLength2(data->svchp, data->errhp, data->locp, data->lenp);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobGetLength2_cb NULL
#endif

sword oci8_OCILobGetLength2_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *lenp, const char *file, int line)
{
    if (have_OCILobGetLength2_nb) {
        oci8_OCILobGetLength2_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.locp = locp;
        data.lenp = lenp;
        oci8_call_without_gvl(svcctx, oci8_OCILobGetLength2_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobGetLength2_nb");
    }
}

/*
 * OCILobRead2_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *locp;
    oraub8 *byte_amtp;
    oraub8 *char_amtp;
    oraub8 offset;
    dvoid *bufp;
    oraub8 bufl;
    ub1 piece;
    dvoid *ctxp;
    OCICallbackLobRead2 cbfp;
    ub2 csid;
    ub1 csfrm;
} oci8_OCILobRead2_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobRead2_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_10_1
static void *oci8_OCILobRead2_cb(void *user_data)
{
    oci8_OCILobRead2_data_t *data = (oci8_OCILobRead2_data_t *)user_data;
    data->rv = OCILobRead2(data->svchp, data->errhp, data->locp, data->byte_amtp, data->char_amtp, data->offset, data->bufp, data->bufl, data->piece, data->ctxp, data->cbfp, data->csid, data->csfrm);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobRead2_cb NULL
#endif

sword oci8_OCILobRead2_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *byte_amtp, oraub8 *char_amtp, oraub8 offset, dvoid *bufp, oraub8 bufl, ub1 piece, dvoid *ctxp, OCICallbackLobRead2 cbfp, ub2 csid, ub1 csfrm, const char *file, int line)
{
    if (have_OCILobRead2_nb) {
        oci8_OCILobRead2_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.locp = locp;
        data.byte_amtp = byte_amtp;
        data.char_amtp = char_amtp;
        data.offset = offset;
        data.bufp = bufp;
        data.bufl = bufl;
        data.piece = piece;
        data.ctxp = ctxp;
        data.cbfp = cbfp;
        data.csid = csid;
        data.csfrm = csfrm;
        oci8_call_without_gvl(svcctx, oci8_OCILobRead2_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobRead2_nb");
    }
}

/*
 * OCILobTrim2_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *locp;
    oraub8 newlen;
} oci8_OCILobTrim2_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobTrim2_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_10_1
static void *oci8_OCILobTrim2_cb(void *user_data)
{
    oci8_OCILobTrim2_data_t *data = (oci8_OCILobTrim2_data_t *)user_data;
    data->rv = OCILobTrim2(data->svchp, data->errhp, data->locp, data->newlen);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobTrim2_cb NULL
#endif

sword oci8_OCILobTrim2_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 newlen, const char *file, int line)
{
    if (have_OCILobTrim2_nb) {
        oci8_OCILobTrim2_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.locp = locp;
        data.newlen = newlen;
        oci8_call_without_gvl(svcctx, oci8_OCILobTrim2_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobTrim2_nb");
    }
}

/*
 * OCILobWrite2_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    OCILobLocator *locp;
    oraub8 *byte_amtp;
    oraub8 *char_amtp;
    oraub8 offset;
    dvoid *bufp;
    oraub8 buflen;
    ub1 piece;
    dvoid *ctxp;
    OCICallbackLobWrite2 cbfp;
    ub2 csid;
    ub1 csfrm;
} oci8_OCILobWrite2_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCILobWrite2_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_10_1
static void *oci8_OCILobWrite2_cb(void *user_data)
{
    oci8_OCILobWrite2_data_t *data = (oci8_OCILobWrite2_data_t *)user_data;
    data->rv = OCILobWrite2(data->svchp, data->errhp, data->locp, data->byte_amtp, data->char_amtp, data->offset, data->bufp, data->buflen, data->piece, data->ctxp, data->cbfp, data->csid, data->csfrm);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCILobWrite2_cb NULL
#endif

sword oci8_OCILobWrite2_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, OCILobLocator *locp, oraub8 *byte_amtp, oraub8 *char_amtp, oraub8 offset, dvoid *bufp, oraub8 buflen, ub1 piece, dvoid *ctxp, OCICallbackLobWrite2 cbfp, ub2 csid, ub1 csfrm, const char *file, int line)
{
    if (have_OCILobWrite2_nb) {
        oci8_OCILobWrite2_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.locp = locp;
        data.byte_amtp = byte_amtp;
        data.char_amtp = char_amtp;
        data.offset = offset;
        data.bufp = bufp;
        data.buflen = buflen;
        data.piece = piece;
        data.ctxp = ctxp;
        data.cbfp = cbfp;
        data.csid = csid;
        data.csfrm = csfrm;
        oci8_call_without_gvl(svcctx, oci8_OCILobWrite2_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCILobWrite2_nb");
    }
}

/*
 * OCIClientVersion
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIClientVersion;
#endif

void oci8_OCIClientVersion(sword *major_version, sword *minor_version, sword *update_num, sword *patch_num, sword *port_update_num, const char *file, int line)
{
    if (have_OCIClientVersion) {
        OCIClientVersion(major_version, minor_version, update_num, patch_num, port_update_num);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIClientVersion");
    }
}

/*
 * OCIPing_nb
 */
typedef struct {
    oci8_svcctx_t *svcctx;
    sword rv;
    OCISvcCtx *svchp;
    OCIError *errhp;
    ub4 mode;
} oci8_OCIPing_data_t;

#if defined RUNTIME_API_CHECK
int oci8_have_OCIPing_nb;
#endif

#if defined RUNTIME_API_CHECK || ORACLE_CLIENT_VERSION >= ORAVER_10_2
static void *oci8_OCIPing_cb(void *user_data)
{
    oci8_OCIPing_data_t *data = (oci8_OCIPing_data_t *)user_data;
    data->rv = OCIPing(data->svchp, data->errhp, data->mode);

    return (void*)(VALUE)data->rv;

}
#else
#define oci8_OCIPing_cb NULL
#endif

sword oci8_OCIPing_nb(oci8_svcctx_t *svcctx, OCISvcCtx *svchp, OCIError *errhp, ub4 mode, const char *file, int line)
{
    if (have_OCIPing_nb) {
        oci8_OCIPing_data_t data;
        data.svcctx = svcctx;
        data.svchp = svchp;
        data.errhp = errhp;
        data.mode = mode;
        oci8_call_without_gvl(svcctx, oci8_OCIPing_cb, &data);
        return data.rv;
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIPing_nb");
    }
}

/*
 * OCIServerRelease2
 */
#if defined RUNTIME_API_CHECK
int oci8_have_OCIServerRelease2;
#endif

sword oci8_OCIServerRelease2(dvoid *hndlp, OCIError *errhp, OraText *bufp, ub4 bufsz, ub1 hndltype, ub4 *version, ub4 mode, const char *file, int line)
{
    if (have_OCIServerRelease2) {
        return OCIServerRelease2(hndlp, errhp, bufp, bufsz, hndltype, version, mode);
    } else {
        rb_raise(rb_eRuntimeError, "undefined OCI function %s is called", "OCIServerRelease2");
    }
}

#if defined RUNTIME_API_CHECK
int oracle_client_version;

void Init_oci8_apiwrap(void)
{
    oracle_client_version = 0;
    oci8_OCIAttrGet_func = (oci8_OCIAttrGet_func_t)oci8_find_symbol("OCIAttrGet");
    if (oci8_OCIAttrGet_func == NULL)
        return;
    oci8_OCIAttrGet_func = (oci8_OCIAttrGet_func_t)oci8_find_symbol("OCIAttrGet");
    if (oci8_OCIAttrGet_func == NULL)
        return;
    oci8_OCIAttrSet_func = (oci8_OCIAttrSet_func_t)oci8_find_symbol("OCIAttrSet");
    if (oci8_OCIAttrSet_func == NULL)
        return;
    oci8_OCIBindArrayOfStruct_func = (oci8_OCIBindArrayOfStruct_func_t)oci8_find_symbol("OCIBindArrayOfStruct");
    if (oci8_OCIBindArrayOfStruct_func == NULL)
        return;
    oci8_OCIBindByName_func = (oci8_OCIBindByName_func_t)oci8_find_symbol("OCIBindByName");
    if (oci8_OCIBindByName_func == NULL)
        return;
    oci8_OCIBindByPos_func = (oci8_OCIBindByPos_func_t)oci8_find_symbol("OCIBindByPos");
    if (oci8_OCIBindByPos_func == NULL)
        return;
    oci8_OCIBindDynamic_func = (oci8_OCIBindDynamic_func_t)oci8_find_symbol("OCIBindDynamic");
    if (oci8_OCIBindDynamic_func == NULL)
        return;
    oci8_OCIBindObject_func = (oci8_OCIBindObject_func_t)oci8_find_symbol("OCIBindObject");
    if (oci8_OCIBindObject_func == NULL)
        return;
    oci8_OCIBreak_func = (oci8_OCIBreak_func_t)oci8_find_symbol("OCIBreak");
    if (oci8_OCIBreak_func == NULL)
        return;
    oci8_OCICollAppend_func = (oci8_OCICollAppend_func_t)oci8_find_symbol("OCICollAppend");
    if (oci8_OCICollAppend_func == NULL)
        return;
    oci8_OCICollAssignElem_func = (oci8_OCICollAssignElem_func_t)oci8_find_symbol("OCICollAssignElem");
    if (oci8_OCICollAssignElem_func == NULL)
        return;
    oci8_OCICollGetElem_func = (oci8_OCICollGetElem_func_t)oci8_find_symbol("OCICollGetElem");
    if (oci8_OCICollGetElem_func == NULL)
        return;
    oci8_OCICollSize_func = (oci8_OCICollSize_func_t)oci8_find_symbol("OCICollSize");
    if (oci8_OCICollSize_func == NULL)
        return;
    oci8_OCICollTrim_func = (oci8_OCICollTrim_func_t)oci8_find_symbol("OCICollTrim");
    if (oci8_OCICollTrim_func == NULL)
        return;
    oci8_OCIDefineArrayOfStruct_func = (oci8_OCIDefineArrayOfStruct_func_t)oci8_find_symbol("OCIDefineArrayOfStruct");
    if (oci8_OCIDefineArrayOfStruct_func == NULL)
        return;
    oci8_OCIDefineByPos_func = (oci8_OCIDefineByPos_func_t)oci8_find_symbol("OCIDefineByPos");
    if (oci8_OCIDefineByPos_func == NULL)
        return;
    oci8_OCIDefineDynamic_func = (oci8_OCIDefineDynamic_func_t)oci8_find_symbol("OCIDefineDynamic");
    if (oci8_OCIDefineDynamic_func == NULL)
        return;
    oci8_OCIDefineObject_func = (oci8_OCIDefineObject_func_t)oci8_find_symbol("OCIDefineObject");
    if (oci8_OCIDefineObject_func == NULL)
        return;
    oci8_OCIDescribeAny_func = (oci8_OCIDescribeAny_func_t)oci8_find_symbol("OCIDescribeAny");
    if (oci8_OCIDescribeAny_func == NULL)
        return;
    oci8_OCIDescriptorAlloc_func = (oci8_OCIDescriptorAlloc_func_t)oci8_find_symbol("OCIDescriptorAlloc");
    if (oci8_OCIDescriptorAlloc_func == NULL)
        return;
    oci8_OCIDescriptorFree_func = (oci8_OCIDescriptorFree_func_t)oci8_find_symbol("OCIDescriptorFree");
    if (oci8_OCIDescriptorFree_func == NULL)
        return;
    oci8_OCIErrorGet_func = (oci8_OCIErrorGet_func_t)oci8_find_symbol("OCIErrorGet");
    if (oci8_OCIErrorGet_func == NULL)
        return;
    oci8_OCIHandleAlloc_func = (oci8_OCIHandleAlloc_func_t)oci8_find_symbol("OCIHandleAlloc");
    if (oci8_OCIHandleAlloc_func == NULL)
        return;
    oci8_OCIHandleFree_func = (oci8_OCIHandleFree_func_t)oci8_find_symbol("OCIHandleFree");
    if (oci8_OCIHandleFree_func == NULL)
        return;
    oci8_OCILobAssign_func = (oci8_OCILobAssign_func_t)oci8_find_symbol("OCILobAssign");
    if (oci8_OCILobAssign_func == NULL)
        return;
    oci8_OCILobFileClose_func = (oci8_OCILobFileClose_func_t)oci8_find_symbol("OCILobFileClose");
    if (oci8_OCILobFileClose_func == NULL)
        return;
    oci8_OCILobFileCloseAll_func = (oci8_OCILobFileCloseAll_func_t)oci8_find_symbol("OCILobFileCloseAll");
    if (oci8_OCILobFileCloseAll_func == NULL)
        return;
    oci8_OCILobFileExists_func = (oci8_OCILobFileExists_func_t)oci8_find_symbol("OCILobFileExists");
    if (oci8_OCILobFileExists_func == NULL)
        return;
    oci8_OCILobFileGetName_func = (oci8_OCILobFileGetName_func_t)oci8_find_symbol("OCILobFileGetName");
    if (oci8_OCILobFileGetName_func == NULL)
        return;
    oci8_OCILobFileOpen_func = (oci8_OCILobFileOpen_func_t)oci8_find_symbol("OCILobFileOpen");
    if (oci8_OCILobFileOpen_func == NULL)
        return;
    oci8_OCILobFileSetName_func = (oci8_OCILobFileSetName_func_t)oci8_find_symbol("OCILobFileSetName");
    if (oci8_OCILobFileSetName_func == NULL)
        return;
    oci8_OCILobLocatorIsInit_func = (oci8_OCILobLocatorIsInit_func_t)oci8_find_symbol("OCILobLocatorIsInit");
    if (oci8_OCILobLocatorIsInit_func == NULL)
        return;
    oci8_OCINumberAbs_func = (oci8_OCINumberAbs_func_t)oci8_find_symbol("OCINumberAbs");
    if (oci8_OCINumberAbs_func == NULL)
        return;
    oci8_OCINumberAdd_func = (oci8_OCINumberAdd_func_t)oci8_find_symbol("OCINumberAdd");
    if (oci8_OCINumberAdd_func == NULL)
        return;
    oci8_OCINumberArcCos_func = (oci8_OCINumberArcCos_func_t)oci8_find_symbol("OCINumberArcCos");
    if (oci8_OCINumberArcCos_func == NULL)
        return;
    oci8_OCINumberArcSin_func = (oci8_OCINumberArcSin_func_t)oci8_find_symbol("OCINumberArcSin");
    if (oci8_OCINumberArcSin_func == NULL)
        return;
    oci8_OCINumberArcTan_func = (oci8_OCINumberArcTan_func_t)oci8_find_symbol("OCINumberArcTan");
    if (oci8_OCINumberArcTan_func == NULL)
        return;
    oci8_OCINumberArcTan2_func = (oci8_OCINumberArcTan2_func_t)oci8_find_symbol("OCINumberArcTan2");
    if (oci8_OCINumberArcTan2_func == NULL)
        return;
    oci8_OCINumberAssign_func = (oci8_OCINumberAssign_func_t)oci8_find_symbol("OCINumberAssign");
    if (oci8_OCINumberAssign_func == NULL)
        return;
    oci8_OCINumberCeil_func = (oci8_OCINumberCeil_func_t)oci8_find_symbol("OCINumberCeil");
    if (oci8_OCINumberCeil_func == NULL)
        return;
    oci8_OCINumberCmp_func = (oci8_OCINumberCmp_func_t)oci8_find_symbol("OCINumberCmp");
    if (oci8_OCINumberCmp_func == NULL)
        return;
    oci8_OCINumberCos_func = (oci8_OCINumberCos_func_t)oci8_find_symbol("OCINumberCos");
    if (oci8_OCINumberCos_func == NULL)
        return;
    oci8_OCINumberDiv_func = (oci8_OCINumberDiv_func_t)oci8_find_symbol("OCINumberDiv");
    if (oci8_OCINumberDiv_func == NULL)
        return;
    oci8_OCINumberExp_func = (oci8_OCINumberExp_func_t)oci8_find_symbol("OCINumberExp");
    if (oci8_OCINumberExp_func == NULL)
        return;
    oci8_OCINumberFloor_func = (oci8_OCINumberFloor_func_t)oci8_find_symbol("OCINumberFloor");
    if (oci8_OCINumberFloor_func == NULL)
        return;
    oci8_OCINumberFromInt_func = (oci8_OCINumberFromInt_func_t)oci8_find_symbol("OCINumberFromInt");
    if (oci8_OCINumberFromInt_func == NULL)
        return;
    oci8_OCINumberFromReal_func = (oci8_OCINumberFromReal_func_t)oci8_find_symbol("OCINumberFromReal");
    if (oci8_OCINumberFromReal_func == NULL)
        return;
    oci8_OCINumberFromText_func = (oci8_OCINumberFromText_func_t)oci8_find_symbol("OCINumberFromText");
    if (oci8_OCINumberFromText_func == NULL)
        return;
    oci8_OCINumberHypCos_func = (oci8_OCINumberHypCos_func_t)oci8_find_symbol("OCINumberHypCos");
    if (oci8_OCINumberHypCos_func == NULL)
        return;
    oci8_OCINumberHypSin_func = (oci8_OCINumberHypSin_func_t)oci8_find_symbol("OCINumberHypSin");
    if (oci8_OCINumberHypSin_func == NULL)
        return;
    oci8_OCINumberHypTan_func = (oci8_OCINumberHypTan_func_t)oci8_find_symbol("OCINumberHypTan");
    if (oci8_OCINumberHypTan_func == NULL)
        return;
    oci8_OCINumberIntPower_func = (oci8_OCINumberIntPower_func_t)oci8_find_symbol("OCINumberIntPower");
    if (oci8_OCINumberIntPower_func == NULL)
        return;
    oci8_OCINumberIsZero_func = (oci8_OCINumberIsZero_func_t)oci8_find_symbol("OCINumberIsZero");
    if (oci8_OCINumberIsZero_func == NULL)
        return;
    oci8_OCINumberLn_func = (oci8_OCINumberLn_func_t)oci8_find_symbol("OCINumberLn");
    if (oci8_OCINumberLn_func == NULL)
        return;
    oci8_OCINumberLog_func = (oci8_OCINumberLog_func_t)oci8_find_symbol("OCINumberLog");
    if (oci8_OCINumberLog_func == NULL)
        return;
    oci8_OCINumberMod_func = (oci8_OCINumberMod_func_t)oci8_find_symbol("OCINumberMod");
    if (oci8_OCINumberMod_func == NULL)
        return;
    oci8_OCINumberMul_func = (oci8_OCINumberMul_func_t)oci8_find_symbol("OCINumberMul");
    if (oci8_OCINumberMul_func == NULL)
        return;
    oci8_OCINumberNeg_func = (oci8_OCINumberNeg_func_t)oci8_find_symbol("OCINumberNeg");
    if (oci8_OCINumberNeg_func == NULL)
        return;
    oci8_OCINumberPower_func = (oci8_OCINumberPower_func_t)oci8_find_symbol("OCINumberPower");
    if (oci8_OCINumberPower_func == NULL)
        return;
    oci8_OCINumberRound_func = (oci8_OCINumberRound_func_t)oci8_find_symbol("OCINumberRound");
    if (oci8_OCINumberRound_func == NULL)
        return;
    oci8_OCINumberSetZero_func = (oci8_OCINumberSetZero_func_t)oci8_find_symbol("OCINumberSetZero");
    if (oci8_OCINumberSetZero_func == NULL)
        return;
    oci8_OCINumberSin_func = (oci8_OCINumberSin_func_t)oci8_find_symbol("OCINumberSin");
    if (oci8_OCINumberSin_func == NULL)
        return;
    oci8_OCINumberSqrt_func = (oci8_OCINumberSqrt_func_t)oci8_find_symbol("OCINumberSqrt");
    if (oci8_OCINumberSqrt_func == NULL)
        return;
    oci8_OCINumberSub_func = (oci8_OCINumberSub_func_t)oci8_find_symbol("OCINumberSub");
    if (oci8_OCINumberSub_func == NULL)
        return;
    oci8_OCINumberTan_func = (oci8_OCINumberTan_func_t)oci8_find_symbol("OCINumberTan");
    if (oci8_OCINumberTan_func == NULL)
        return;
    oci8_OCINumberToInt_func = (oci8_OCINumberToInt_func_t)oci8_find_symbol("OCINumberToInt");
    if (oci8_OCINumberToInt_func == NULL)
        return;
    oci8_OCINumberToReal_func = (oci8_OCINumberToReal_func_t)oci8_find_symbol("OCINumberToReal");
    if (oci8_OCINumberToReal_func == NULL)
        return;
    oci8_OCINumberToText_func = (oci8_OCINumberToText_func_t)oci8_find_symbol("OCINumberToText");
    if (oci8_OCINumberToText_func == NULL)
        return;
    oci8_OCINumberTrunc_func = (oci8_OCINumberTrunc_func_t)oci8_find_symbol("OCINumberTrunc");
    if (oci8_OCINumberTrunc_func == NULL)
        return;
    oci8_OCIObjectFree_func = (oci8_OCIObjectFree_func_t)oci8_find_symbol("OCIObjectFree");
    if (oci8_OCIObjectFree_func == NULL)
        return;
    oci8_OCIObjectGetInd_func = (oci8_OCIObjectGetInd_func_t)oci8_find_symbol("OCIObjectGetInd");
    if (oci8_OCIObjectGetInd_func == NULL)
        return;
    oci8_OCIObjectGetTypeRef_func = (oci8_OCIObjectGetTypeRef_func_t)oci8_find_symbol("OCIObjectGetTypeRef");
    if (oci8_OCIObjectGetTypeRef_func == NULL)
        return;
    oci8_OCIObjectNew_func = (oci8_OCIObjectNew_func_t)oci8_find_symbol("OCIObjectNew");
    if (oci8_OCIObjectNew_func == NULL)
        return;
    oci8_OCIObjectPin_func = (oci8_OCIObjectPin_func_t)oci8_find_symbol("OCIObjectPin");
    if (oci8_OCIObjectPin_func == NULL)
        return;
    oci8_OCIObjectUnpin_func = (oci8_OCIObjectUnpin_func_t)oci8_find_symbol("OCIObjectUnpin");
    if (oci8_OCIObjectUnpin_func == NULL)
        return;
    oci8_OCIParamGet_func = (oci8_OCIParamGet_func_t)oci8_find_symbol("OCIParamGet");
    if (oci8_OCIParamGet_func == NULL)
        return;
    oci8_OCIRawAssignBytes_func = (oci8_OCIRawAssignBytes_func_t)oci8_find_symbol("OCIRawAssignBytes");
    if (oci8_OCIRawAssignBytes_func == NULL)
        return;
    oci8_OCIRawPtr_func = (oci8_OCIRawPtr_func_t)oci8_find_symbol("OCIRawPtr");
    if (oci8_OCIRawPtr_func == NULL)
        return;
    oci8_OCIRawSize_func = (oci8_OCIRawSize_func_t)oci8_find_symbol("OCIRawSize");
    if (oci8_OCIRawSize_func == NULL)
        return;
    oci8_OCIServerAttach_func = (oci8_OCIServerAttach_func_t)oci8_find_symbol("OCIServerAttach");
    if (oci8_OCIServerAttach_func == NULL)
        return;
    oci8_OCIServerDetach_func = (oci8_OCIServerDetach_func_t)oci8_find_symbol("OCIServerDetach");
    if (oci8_OCIServerDetach_func == NULL)
        return;
    oci8_OCIServerVersion_func = (oci8_OCIServerVersion_func_t)oci8_find_symbol("OCIServerVersion");
    if (oci8_OCIServerVersion_func == NULL)
        return;
    oci8_OCISessionBegin_func = (oci8_OCISessionBegin_func_t)oci8_find_symbol("OCISessionBegin");
    if (oci8_OCISessionBegin_func == NULL)
        return;
    oci8_OCISessionEnd_func = (oci8_OCISessionEnd_func_t)oci8_find_symbol("OCISessionEnd");
    if (oci8_OCISessionEnd_func == NULL)
        return;
    oci8_OCIStmtExecute_func = (oci8_OCIStmtExecute_func_t)oci8_find_symbol("OCIStmtExecute");
    if (oci8_OCIStmtExecute_func == NULL)
        return;
    oci8_OCIStmtFetch_func = (oci8_OCIStmtFetch_func_t)oci8_find_symbol("OCIStmtFetch");
    if (oci8_OCIStmtFetch_func == NULL)
        return;
    oci8_OCIStringAssignText_func = (oci8_OCIStringAssignText_func_t)oci8_find_symbol("OCIStringAssignText");
    if (oci8_OCIStringAssignText_func == NULL)
        return;
    oci8_OCIStringPtr_func = (oci8_OCIStringPtr_func_t)oci8_find_symbol("OCIStringPtr");
    if (oci8_OCIStringPtr_func == NULL)
        return;
    oci8_OCIStringSize_func = (oci8_OCIStringSize_func_t)oci8_find_symbol("OCIStringSize");
    if (oci8_OCIStringSize_func == NULL)
        return;
    oci8_OCITransCommit_func = (oci8_OCITransCommit_func_t)oci8_find_symbol("OCITransCommit");
    if (oci8_OCITransCommit_func == NULL)
        return;
    oci8_OCITransRollback_func = (oci8_OCITransRollback_func_t)oci8_find_symbol("OCITransRollback");
    if (oci8_OCITransRollback_func == NULL)
        return;
    oci8_OCITransRollback_func = (oci8_OCITransRollback_func_t)oci8_find_symbol("OCITransRollback");
    if (oci8_OCITransRollback_func == NULL)
        return;
    oci8_OCITypeTypeCode_func = (oci8_OCITypeTypeCode_func_t)oci8_find_symbol("OCITypeTypeCode");
    if (oci8_OCITypeTypeCode_func == NULL)
        return;
    /* pass Oracle 8.0.0 API */
    oracle_client_version = ORAVER_8_0;
    have_OCIAttrGet = 1;
    have_OCIAttrGet_nb = 1;
    have_OCIAttrSet = 1;
    have_OCIBindArrayOfStruct = 1;
    have_OCIBindByName = 1;
    have_OCIBindByPos = 1;
    have_OCIBindDynamic = 1;
    have_OCIBindObject = 1;
    have_OCIBreak = 1;
    have_OCICollAppend = 1;
    have_OCICollAssignElem = 1;
    have_OCICollGetElem = 1;
    have_OCICollSize = 1;
    have_OCICollTrim = 1;
    have_OCIDefineArrayOfStruct = 1;
    have_OCIDefineByPos = 1;
    have_OCIDefineDynamic = 1;
    have_OCIDefineObject = 1;
    have_OCIDescribeAny_nb = 1;
    have_OCIDescriptorAlloc = 1;
    have_OCIDescriptorFree = 1;
    have_OCIErrorGet = 1;
    have_OCIHandleAlloc = 1;
    have_OCIHandleFree = 1;
    have_OCILobAssign = 1;
    have_OCILobFileClose_nb = 1;
    have_OCILobFileCloseAll_nb = 1;
    have_OCILobFileExists_nb = 1;
    have_OCILobFileGetName = 1;
    have_OCILobFileOpen_nb = 1;
    have_OCILobFileSetName = 1;
    have_OCILobLocatorIsInit = 1;
    have_OCINumberAbs = 1;
    have_OCINumberAdd = 1;
    have_OCINumberArcCos = 1;
    have_OCINumberArcSin = 1;
    have_OCINumberArcTan = 1;
    have_OCINumberArcTan2 = 1;
    have_OCINumberAssign = 1;
    have_OCINumberCeil = 1;
    have_OCINumberCmp = 1;
    have_OCINumberCos = 1;
    have_OCINumberDiv = 1;
    have_OCINumberExp = 1;
    have_OCINumberFloor = 1;
    have_OCINumberFromInt = 1;
    have_OCINumberFromReal = 1;
    have_OCINumberFromText = 1;
    have_OCINumberHypCos = 1;
    have_OCINumberHypSin = 1;
    have_OCINumberHypTan = 1;
    have_OCINumberIntPower = 1;
    have_OCINumberIsZero = 1;
    have_OCINumberLn = 1;
    have_OCINumberLog = 1;
    have_OCINumberMod = 1;
    have_OCINumberMul = 1;
    have_OCINumberNeg = 1;
    have_OCINumberPower = 1;
    have_OCINumberRound = 1;
    have_OCINumberSetZero = 1;
    have_OCINumberSin = 1;
    have_OCINumberSqrt = 1;
    have_OCINumberSub = 1;
    have_OCINumberTan = 1;
    have_OCINumberToInt = 1;
    have_OCINumberToReal = 1;
    have_OCINumberToText = 1;
    have_OCINumberTrunc = 1;
    have_OCIObjectFree = 1;
    have_OCIObjectGetInd = 1;
    have_OCIObjectGetTypeRef = 1;
    have_OCIObjectNew = 1;
    have_OCIObjectPin_nb = 1;
    have_OCIObjectUnpin = 1;
    have_OCIParamGet = 1;
    have_OCIRawAssignBytes = 1;
    have_OCIRawPtr = 1;
    have_OCIRawSize = 1;
    have_OCIServerAttach_nb = 1;
    have_OCIServerDetach = 1;
    have_OCIServerVersion = 1;
    have_OCISessionBegin_nb = 1;
    have_OCISessionEnd = 1;
    have_OCIStmtExecute_nb = 1;
    have_OCIStmtFetch_nb = 1;
    have_OCIStringAssignText = 1;
    have_OCIStringPtr = 1;
    have_OCIStringSize = 1;
    have_OCITransCommit_nb = 1;
    have_OCITransRollback = 1;
    have_OCITransRollback_nb = 1;
    have_OCITypeTypeCode = 1;

    /*
     * checking Oracle 8.1.0 API
     */
    oci8_OCIEnvCreate_func = (oci8_OCIEnvCreate_func_t)oci8_find_symbol("OCIEnvCreate");
    if (oci8_OCIEnvCreate_func == NULL)
        return;
    oci8_OCILobClose_func = (oci8_OCILobClose_func_t)oci8_find_symbol("OCILobClose");
    if (oci8_OCILobClose_func == NULL)
        return;
    oci8_OCILobCreateTemporary_func = (oci8_OCILobCreateTemporary_func_t)oci8_find_symbol("OCILobCreateTemporary");
    if (oci8_OCILobCreateTemporary_func == NULL)
        return;
    oci8_OCILobFreeTemporary_func = (oci8_OCILobFreeTemporary_func_t)oci8_find_symbol("OCILobFreeTemporary");
    if (oci8_OCILobFreeTemporary_func == NULL)
        return;
    oci8_OCILobGetChunkSize_func = (oci8_OCILobGetChunkSize_func_t)oci8_find_symbol("OCILobGetChunkSize");
    if (oci8_OCILobGetChunkSize_func == NULL)
        return;
    oci8_OCILobIsTemporary_func = (oci8_OCILobIsTemporary_func_t)oci8_find_symbol("OCILobIsTemporary");
    if (oci8_OCILobIsTemporary_func == NULL)
        return;
    oci8_OCILobLocatorAssign_func = (oci8_OCILobLocatorAssign_func_t)oci8_find_symbol("OCILobLocatorAssign");
    if (oci8_OCILobLocatorAssign_func == NULL)
        return;
    oci8_OCILobOpen_func = (oci8_OCILobOpen_func_t)oci8_find_symbol("OCILobOpen");
    if (oci8_OCILobOpen_func == NULL)
        return;
    oci8_OCIMessageGet_func = (oci8_OCIMessageGet_func_t)oci8_find_symbol("OCIMessageGet");
    if (oci8_OCIMessageGet_func == NULL)
        return;
    oci8_OCIMessageOpen_func = (oci8_OCIMessageOpen_func_t)oci8_find_symbol("OCIMessageOpen");
    if (oci8_OCIMessageOpen_func == NULL)
        return;
    oci8_OCINumberIsInt_func = (oci8_OCINumberIsInt_func_t)oci8_find_symbol("OCINumberIsInt");
    if (oci8_OCINumberIsInt_func == NULL)
        return;
    oci8_OCINumberPrec_func = (oci8_OCINumberPrec_func_t)oci8_find_symbol("OCINumberPrec");
    if (oci8_OCINumberPrec_func == NULL)
        return;
    oci8_OCINumberSetPi_func = (oci8_OCINumberSetPi_func_t)oci8_find_symbol("OCINumberSetPi");
    if (oci8_OCINumberSetPi_func == NULL)
        return;
    oci8_OCINumberShift_func = (oci8_OCINumberShift_func_t)oci8_find_symbol("OCINumberShift");
    if (oci8_OCINumberShift_func == NULL)
        return;
    oci8_OCINumberSign_func = (oci8_OCINumberSign_func_t)oci8_find_symbol("OCINumberSign");
    if (oci8_OCINumberSign_func == NULL)
        return;
    /* pass Oracle 8.1.0 API */
    oracle_client_version = ORAVER_8_1;
    have_OCIEnvCreate = 1;
    have_OCILobClose_nb = 1;
    have_OCILobCreateTemporary_nb = 1;
    have_OCILobFreeTemporary = 1;
    have_OCILobGetChunkSize_nb = 1;
    have_OCILobIsTemporary = 1;
    have_OCILobLocatorAssign_nb = 1;
    have_OCILobOpen_nb = 1;
    have_OCIMessageGet = 1;
    have_OCIMessageOpen = 1;
    have_OCINumberIsInt = 1;
    have_OCINumberPrec = 1;
    have_OCINumberSetPi = 1;
    have_OCINumberShift = 1;
    have_OCINumberSign = 1;

    /*
     * checking Oracle 9.0.0 API
     */
    oci8_OCIConnectionPoolCreate_func = (oci8_OCIConnectionPoolCreate_func_t)oci8_find_symbol("OCIConnectionPoolCreate");
    if (oci8_OCIConnectionPoolCreate_func == NULL)
        return;
    oci8_OCIConnectionPoolDestroy_func = (oci8_OCIConnectionPoolDestroy_func_t)oci8_find_symbol("OCIConnectionPoolDestroy");
    if (oci8_OCIConnectionPoolDestroy_func == NULL)
        return;
    oci8_OCIDateTimeConstruct_func = (oci8_OCIDateTimeConstruct_func_t)oci8_find_symbol("OCIDateTimeConstruct");
    if (oci8_OCIDateTimeConstruct_func == NULL)
        return;
    oci8_OCIDateTimeGetDate_func = (oci8_OCIDateTimeGetDate_func_t)oci8_find_symbol("OCIDateTimeGetDate");
    if (oci8_OCIDateTimeGetDate_func == NULL)
        return;
    oci8_OCIDateTimeGetTime_func = (oci8_OCIDateTimeGetTime_func_t)oci8_find_symbol("OCIDateTimeGetTime");
    if (oci8_OCIDateTimeGetTime_func == NULL)
        return;
    oci8_OCIDateTimeGetTimeZoneOffset_func = (oci8_OCIDateTimeGetTimeZoneOffset_func_t)oci8_find_symbol("OCIDateTimeGetTimeZoneOffset");
    if (oci8_OCIDateTimeGetTimeZoneOffset_func == NULL)
        return;
    oci8_OCIIntervalGetDaySecond_func = (oci8_OCIIntervalGetDaySecond_func_t)oci8_find_symbol("OCIIntervalGetDaySecond");
    if (oci8_OCIIntervalGetDaySecond_func == NULL)
        return;
    oci8_OCIIntervalGetYearMonth_func = (oci8_OCIIntervalGetYearMonth_func_t)oci8_find_symbol("OCIIntervalGetYearMonth");
    if (oci8_OCIIntervalGetYearMonth_func == NULL)
        return;
    oci8_OCIIntervalSetDaySecond_func = (oci8_OCIIntervalSetDaySecond_func_t)oci8_find_symbol("OCIIntervalSetDaySecond");
    if (oci8_OCIIntervalSetDaySecond_func == NULL)
        return;
    oci8_OCIIntervalSetYearMonth_func = (oci8_OCIIntervalSetYearMonth_func_t)oci8_find_symbol("OCIIntervalSetYearMonth");
    if (oci8_OCIIntervalSetYearMonth_func == NULL)
        return;
    oci8_OCIRowidToChar_func = (oci8_OCIRowidToChar_func_t)oci8_find_symbol("OCIRowidToChar");
    if (oci8_OCIRowidToChar_func == NULL)
        return;
    oci8_OCIServerRelease_func = (oci8_OCIServerRelease_func_t)oci8_find_symbol("OCIServerRelease");
    if (oci8_OCIServerRelease_func == NULL)
        return;
    /* pass Oracle 9.0.0 API */
    oracle_client_version = ORAVER_9_0;
    have_OCIConnectionPoolCreate = 1;
    have_OCIConnectionPoolDestroy = 1;
    have_OCIDateTimeConstruct = 1;
    have_OCIDateTimeGetDate = 1;
    have_OCIDateTimeGetTime = 1;
    have_OCIDateTimeGetTimeZoneOffset = 1;
    have_OCIIntervalGetDaySecond = 1;
    have_OCIIntervalGetYearMonth = 1;
    have_OCIIntervalSetDaySecond = 1;
    have_OCIIntervalSetYearMonth = 1;
    have_OCIRowidToChar = 1;
    have_OCIServerRelease = 1;

    /*
     * checking Oracle 9.2.0 API
     */
    oci8_OCINlsCharSetIdToName_func = (oci8_OCINlsCharSetIdToName_func_t)oci8_find_symbol("OCINlsCharSetIdToName");
    if (oci8_OCINlsCharSetIdToName_func == NULL)
        return;
    oci8_OCINlsCharSetNameToId_func = (oci8_OCINlsCharSetNameToId_func_t)oci8_find_symbol("OCINlsCharSetNameToId");
    if (oci8_OCINlsCharSetNameToId_func == NULL)
        return;
    oci8_OCIStmtPrepare2_func = (oci8_OCIStmtPrepare2_func_t)oci8_find_symbol("OCIStmtPrepare2");
    if (oci8_OCIStmtPrepare2_func == NULL)
        return;
    oci8_OCIStmtRelease_func = (oci8_OCIStmtRelease_func_t)oci8_find_symbol("OCIStmtRelease");
    if (oci8_OCIStmtRelease_func == NULL)
        return;
    /* pass Oracle 9.2.0 API */
    oracle_client_version = ORAVER_9_2;
    have_OCINlsCharSetIdToName = 1;
    have_OCINlsCharSetNameToId = 1;
    have_OCIStmtPrepare2 = 1;
    have_OCIStmtRelease = 1;

    /*
     * checking Oracle 10.1.0 API
     */
    oci8_OCILobGetLength2_func = (oci8_OCILobGetLength2_func_t)oci8_find_symbol("OCILobGetLength2");
    if (oci8_OCILobGetLength2_func == NULL)
        return;
    oci8_OCILobRead2_func = (oci8_OCILobRead2_func_t)oci8_find_symbol("OCILobRead2");
    if (oci8_OCILobRead2_func == NULL)
        return;
    oci8_OCILobTrim2_func = (oci8_OCILobTrim2_func_t)oci8_find_symbol("OCILobTrim2");
    if (oci8_OCILobTrim2_func == NULL)
        return;
    oci8_OCILobWrite2_func = (oci8_OCILobWrite2_func_t)oci8_find_symbol("OCILobWrite2");
    if (oci8_OCILobWrite2_func == NULL)
        return;
    /* pass Oracle 10.1.0 API */
    oracle_client_version = ORAVER_10_1;
    have_OCILobGetLength2_nb = 1;
    have_OCILobRead2_nb = 1;
    have_OCILobTrim2_nb = 1;
    have_OCILobWrite2_nb = 1;

    /*
     * checking Oracle 10.2.0 API
     */
    oci8_OCIClientVersion_func = (oci8_OCIClientVersion_func_t)oci8_find_symbol("OCIClientVersion");
    if (oci8_OCIClientVersion_func == NULL)
        return;
    oci8_OCIPing_func = (oci8_OCIPing_func_t)oci8_find_symbol("OCIPing");
    if (oci8_OCIPing_func == NULL)
        return;
    /* pass Oracle 10.2.0 API */
    oracle_client_version = ORAVER_10_2;
    have_OCIClientVersion = 1;
    have_OCIPing_nb = 1;

    /*
     * checking Oracle 18.0.0 API
     */
    oci8_OCIServerRelease2_func = (oci8_OCIServerRelease2_func_t)oci8_find_symbol("OCIServerRelease2");
    if (oci8_OCIServerRelease2_func == NULL)
        return;
    /* pass Oracle 18.0.0 API */
    oracle_client_version = ORAVER_18;
    have_OCIServerRelease2 = 1;
}
#endif /* RUNTIME_API_CHECK */
