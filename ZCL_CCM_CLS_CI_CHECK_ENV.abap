class ZCL_CCM_CLS_CI_CHECK_ENV definition
  public
  inheriting from CL_CI_TEST_ABAP_COMP_PROCS
  create public .

public section.

  types:
    begin of ty_object,
        object    type tadir-object,
        obj_name  type tadir-obj_name,
        devclass  type tadir-devclass,
        dlvunit   type tdevc-dlvunit,
        namespace type tdevc-namespace,
        ps_posid  type df14l-ps_posid,
      end of ty_object .
  types:
    ty_tab_objects type standard table of ty_object .
  types:
    begin of
        ty_static_ref_info_complete,
        target_full_name type scr_token_ref-full_name,
        obj_include      type programm,
        obj_row          type i,
        obj_column       type int2,
        proc_entry       type ref to cl_abap_comp_procs=>t_proc_entry,
        stmt_index       type i,
      end of ty_static_ref_info_complete .
  types:
    ty_static_refs_info_complete type standard table of ty_static_ref_info_complete
         with key obj_include target_full_name .
  types:
** Begin of Change
    BEGIN OF ty_obj_chng_dscr,
        tadirObject   TYPE trobjtype,
        tadirObjName TYPE sobj_name,
        decsription TYPE string,
      END OF ty_obj_chng_dscr .
  types:
    tt_obj_chng_dscr TYPE STANDARD TABLE OF ty_obj_chng_dscr WITH EMPTY KEY .
  types:
    BEGIN OF ty_obj_det_full,
        Info TYPE string,
        objectChangeDetails  TYPE tt_obj_chng_dscr,
      END OF ty_obj_det_full .

  data MS_OBJ_CHNG_DET_FRM_CUST_SIDB type TY_OBJ_DET_FULL .
** End of Change
  data L_DESTINATION type RFCDEST .

  methods CONSTRUCTOR .
  methods LOAD_CHNG_SIDBDET_FROM_GIT
    importing
      !I_GIT_URL type SYCM_URL optional
    returning
      value(RS_OBJ_SIDBCHNG_DET_FRM_GIT) type TY_OBJ_DET_FULL .

  methods GET_ATTRIBUTES
    redefinition .
  methods GET_DETAIL
    redefinition .
  methods GET_RESULT_NODE
    redefinition .
  methods IF_CI_TEST~QUERY_ATTRIBUTES
    redefinition .
  methods PUT_ATTRIBUTES
    redefinition .
  methods RUN
    redefinition .
  methods RUN_BEGIN
    redefinition .
  methods VERIFY_TEST
    redefinition .
protected section.

  types:
    begin of ty_successor,
               successor_classification type ars_successor_classification  ,
               successor_object_type type ars_sub_object_type,
                successor_object_key type ars_sub_object_name,
                successor_tadir_object type trobjtype,
                successor_tadir_obj_name type sobj_name,
                end of TY_SUCCESSOR .

  constants MCODE_FORBIDDEN type SCI_ERRC value '1' ##NO_TEXT.
  constants MCODE_TECHN_FORBIDDEN type SCI_ERRC value '2' ##NO_TEXT.
  constants MCODE_DEPRECATED type SCI_ERRC value '4' ##NO_TEXT.
  constants MCODE_FORBIDDEN_APP type SCI_ERRC value '5' ##NO_TEXT.
  constants MCODE_DIFF_CUST_SWC type SCI_ERRC value '6' ##NO_TEXT.
  constants MCODE_FORBIDDEN_UI type SCI_ERRC value '7' ##NO_TEXT.
  constants MCODE_NOT_TO_REL type SCI_ERRC value 'NOT_TO_REL' ##NO_TEXT.
  data:
    checkable_namespaces type standard table of namespace .
  data API_MESSAGES type SYCH_OBJECT_USAGE_MESSAGES .

  methods CREATE_QUICKFIXES
    importing
      !I_USAG type CL_CLS_CI_CHECK_ENVIRONMENT=>TY_STATIC_REF_INFO_COMPLETE
      !I_REF_OBJECT_NAME type SOBJ_NAME
      !I_REF_OBJECT_TYPE type TROBJTYPE
      !I_PROC_DEF type CL_ABAP_COMP_PROCS=>T_PROC_ENTRY
      !IS_RELEVANT_STATEMENT type CL_ABAP_COMP_PROCS=>T_STMT
    changing
      !CT_DETAILS type SCIT_DETAIL
      !CT_QUICKFIXES type CL_CI_QUICKFIX_CREATION=>T_QUICKFIXES
    raising
      CX_CI_QUICKFIX_FAILED .
  methods REPORT_FINDING
    importing
      !I_SUB_OBJ_TYPE type TROBJTYPE
      !I_SUB_OBJ_NAME type SOBJ_NAME
      !I_DETAIL type XSTRING
      !I_REF_OBJECT_TYPE type TROBJTYPE
      !I_REF_OBJECT_NAME type SOBJ_NAME
      !I_LINE type TOKEN_ROW
      !I_COLUMN type TOKEN_COL
      !I_KIND type SYCHAR01
      !I_CODE type SCI_ERRC
      !I_APPL_COMPONENT type DF14L-PS_POSID
      !I_CHECKSUM type SCI_CRC64
      !I_FINDING_ORIGINS type CL_ABAP_COMP_PROCS=>T_ORIGINS .
  methods DO_UC5CHECK
    importing
      !I_ROOT_OBJECT type SYCH_OBJECT_ENTRY
      !I_USAGES type SYCH_OBJECT_USAGE
    returning
      value(R_ERRORS) type SYCH_OBJECT_USAGE .
  methods DO_UC2CHECK
    importing
      !I_ROOT_OBJECT type SYCH_OBJECT_ENTRY
      !I_USAGES type SYCH_OBJECT_USAGE
    returning
      value(R_ERRORS) type SYCH_OBJECT_USAGE .
  methods GET_SUCCESSOR
    importing
      !I_REF_OBJECT_NAME type SOBJ_NAME
      !I_OBJECT_TYPE like IF_ARS_ABAP_OBJECT_CHECK=>GC_SUB_OBJECT_TYPE-CDS_ENTITY
    returning
      value(R_REPLACEMENT) type TY_SUCCESSOR .
  methods DETERMINE_FINDING_CODE
    importing
      !I_APPLICATION_COMPONENT type DF14L-PS_POSID
      !I_SOFTWARE_COMPONENT type DLVUNIT
      !I_OBJECT_TYPE type TROBJTYPE
      !I_OBJECT_NAME type SOBJ_NAME
      !I_ERR_ENTRY type SYCH_OBJECT_USAGE_ENTRY
    returning
      value(R_CODE) type SCI_ERRC .
private section.

  types:
    begin of ty_ddtypes_resolved,
        fullname type string,
        obj_type type tadir-object,
        obj_name type tadir-obj_name,
      end of ty_ddtypes_resolved .
  types:
    ty_tab_ddtypes_resolved type standard table of ty_ddtypes_resolved .
  types:
    begin of ty_tabl_kind,
        tabl_name type ddobjname,
        tabclass  type tabclass,
      end of ty_tabl_kind .
  types:
    ty_tt_tabl_kind type sorted table of ty_tabl_kind with unique key tabl_name .

  data DDYPES_RESOLVED type TY_TAB_DDTYPES_RESOLVED .
  data TADIR_RESOLVED type TY_TAB_OBJECTS .
  data SREFS_PROGRAM_COMPLETE type TY_STATIC_REFS_INFO_COMPLETE .
  constants GC_OBJECT_TYPE_AUTH type TROBJTYPE value 'AUTH' ##NO_TEXT.
  constants GC_OBJECT_TYPE_CLAS type TROBJTYPE value 'CLAS' ##NO_TEXT.
  constants GC_OBJECT_TYPE_DIAL type TROBJTYPE value 'DIAL' ##NO_TEXT.
  constants GC_OBJECT_TYPE_DOMA type TROBJTYPE value 'DOMA' ##NO_TEXT.
  constants GC_OBJECT_TYPE_DTEL type TROBJTYPE value 'DTEL' ##NO_TEXT.
  constants GC_OBJECT_TYPE_ENQU type TROBJTYPE value 'ENQU' ##NO_TEXT.
  constants GC_OBJECT_TYPE_FUGR type TROBJTYPE value 'FUGR' ##NO_TEXT.
  constants GC_OBJECT_TYPE_FUNC type TROBJTYPE value 'FUNC' ##NO_TEXT.
  constants GC_OBJECT_TYPE_FUGS type TROBJTYPE value 'FUGS' ##NO_TEXT.
  constants GC_OBJECT_TYPE_FUGX type TROBJTYPE value 'FUGX' ##NO_TEXT.
  constants GC_OBJECT_TYPE_INTF type TROBJTYPE value 'INTF' ##NO_TEXT.
  constants GC_OBJECT_TYPE_LDBA type TROBJTYPE value 'LDBA' ##NO_TEXT.
  constants GC_OBJECT_TYPE_PROG type TROBJTYPE value 'PROG' ##NO_TEXT.
  constants GC_OBJECT_TYPE_REPS type TROBJTYPE value 'REPS' ##NO_TEXT.
  constants GC_OBJECT_TYPE_SHLP type TROBJTYPE value 'SHLP' ##NO_TEXT.
  constants GC_OBJECT_TYPE_SQLT type TROBJTYPE value 'SQLT' ##NO_TEXT.
  constants GC_OBJECT_TYPE_SQSC type TROBJTYPE value 'SQSC' ##NO_TEXT.
  constants GC_OBJECT_TYPE_SUSO type TROBJTYPE value 'SUSO' ##NO_TEXT.
  constants GC_OBJECT_TYPE_TABL type TROBJTYPE value 'TABL' ##NO_TEXT.
  constants GC_OBJECT_TYPE_TTYP type TROBJTYPE value 'TTYP' ##NO_TEXT.
  constants GC_OBJECT_TYPE_TRAN type TROBJTYPE value 'TRAN' ##NO_TEXT.
  constants GC_OBJECT_TYPE_TYPE type TROBJTYPE value 'TYPE' ##NO_TEXT.
  constants GC_OBJECT_TYPE_VIEW type TROBJTYPE value 'VIEW' ##NO_TEXT.
  constants GC_OBJECT_TYPE_WDYN type TROBJTYPE value 'WDYN' ##NO_TEXT.
  constants GC_OBJECT_TYPE_DDLS type TROBJTYPE value 'DDLS' ##NO_TEXT.
  constants GC_OBJECT_TYPE_STOB type TROBJTYPE value 'STOB' ##NO_TEXT.
  constants MCODE___RFC_ERROR__ type SCI_ERRC value '__RFCERR__' ##NO_TEXT.
  constants MCODE___FULLN_ERROR__ type SCI_ERRC value '__FULERR__' ##NO_TEXT.
  constants C_DB_ACCESS type STRING value `DB_ACCESS - ` ##NO_TEXT.
  data MTEXT___RFC_ERROR__ type SCIMESSAGE-TEXT .
  data REMOTE_API_EXISTS type ABAP_BOOL value ABAP_FALSE ##NO_TEXT.
  data REMOTE_API_OBJ_INFO_EXISTS type ABAP_BOOL value ABAP_FALSE ##NO_TEXT.
  data PA_VRS_2_KEY_USR type FLAG .
  data PA_VRS_5_ABAP_CP type FLAG .
  data TABL_KIND type TY_TT_TABL_KIND .

  methods REPORT_UC5CHECK_ERRORS
    importing
      !REFERENCED_OBJECTS type CL_YCM_FULLNAME_PROCESSOR=>TTY_ID_MAPPING
    changing
      !ERRORS type SYCH_OBJECT_USAGE .
  methods DETERMINE_CHECKSUM_NON_SRC
    importing
      !I_REF_OBJECT_TYPE type TROBJTYPE
      !I_REF_OBJECT_NAME type SOBJ_NAME
    returning
      value(R_CHECKSUM) type SCI_CRC64 .
  methods FILL_ENVIRONMENT_TYPES
    changing
      !ENVIRONMENT_TYPES type ENVI_TYPES .
  methods PROCESS_NON_SRCCODE_ARTIFACT
    exporting
      !ENVIRONMENT_TAB type SENVI_TAB
    exceptions
      RFC_CALL_ERROR .
  methods PROCESS_SRCCODE_ARTIFACT
    exporting
      !E_REFERENCED_OBJECTS type CL_YCM_FULLNAME_PROCESSOR=>TTY_ID_MAPPING .
  methods ADJUST_FUNC_ERRORS
    changing
      !C_ERRORS type SYCH_OBJECT_USAGE .
  methods LOOKUP_IN_DDTYPES
    changing
      !CS_REF type CL_YCM_FULLNAME_PROCESSOR=>TY_ID_MAPPING .
  methods EXTRACT_SREFS_COMP_PROC_DEF
    importing
      !P_PROC_DEF type CL_ABAP_COMP_PROCS=>T_PROC_ENTRY
    exporting
      value(RESULT) type CL_YCM_FULLNAME_PROCESSOR=>TTY_FULLNAMES
      value(RESULT_COMPLETE) type TY_STATIC_REFS_INFO_COMPLETE .
  methods DETERMINE_STATIC_REFS
    exporting
      value(R_SREFS_FULLNAMES) type CL_YCM_FULLNAME_PROCESSOR=>TTY_FULLNAMES
      value(R_SREFS_PROGRAM_COMPLETE) type TY_STATIC_REFS_INFO_COMPLETE .
  methods PREPARE_AND_REPORT
    importing
      !I_REF_OBJECT_TYPE type TROBJTYPE
      !I_REF_OBJECT_NAME type SOBJ_NAME
      !I_KIND type SYCHAR01
      !I_CODE type SCI_ERRC
      !I_APPLICATION_COMPONENT type DF14L-PS_POSID
      !I_USAG type CL_CLS_CI_CHECK_ENVIRONMENT=>TY_STATIC_REF_INFO_COMPLETE
      !I_DETAILS type SCIT_DETAIL .
  methods GET_UPCASTED_FULLNAME
    importing
      !FULLNAME type STRING
    exporting
      !FULLNAME_UPCASTED type STRING .
  methods FILL_DETAILS
    importing
      !I_REF_OBJECT_TYPE_REF type ref to TROBJTYPE
      !I_REF_OBJECT_NAME_REF type ref to SOBJ_NAME
      !I_APPLICATION_COMPONENT_REF type ref to DF14L-PS_POSID
      !I_MESSAGE type SYMSG
      !I_DEVCLASS_REF type ref to DEVCLASS
      !I_SOFTWARE_COMPONENT_REF type ref to DLVUNIT
      !I_ADDITIONAL_INFO type ref to STRING optional
    returning
      value(R_DETAILS) type SCIT_DETAIL .
  methods MAP_WHITELIST_ERR_TO_ALL_POS
    importing
      !I_REFERENCED_OBJECTS type CL_YCM_FULLNAME_PROCESSOR=>TTY_ID_MAPPING
      !I_REF_OBJECT_TYPE type TROBJTYPE
      !I_REF_OBJECT_NAME type SOBJ_NAME
      !I_KIND type SYCHAR01
      !I_CODE type SCI_ERRC
      !I_APPLICATION_COMPONENT type DF14L-PS_POSID
    changing
      !C_DETAILS type SCIT_DETAIL .
  methods REPORT_FINDING_FOR_NON_SRC
    importing
      !I_REF_OBJECT_TYPE type TROBJTYPE
      !I_REF_OBJECT_NAME type SOBJ_NAME
      !I_LINE type TOKEN_ROW
      !I_COLUMN type TOKEN_COL
      !I_KIND type SYCHAR01
      !I_CODE type SCI_ERRC
      !I_APPLICATION_COMPONENT type DF14L-PS_POSID
    changing
      !C_DETAILS type SCIT_DETAIL .
  methods GET_NEW_CODE
    importing
      !I_REF_OBJECT_NAME type SOBJ_NAME
      !I_OLD_TOKEN type CL_ABAP_COMP_PROCS=>T_TOKEN-STR
      !I_SUCCESSOR_KEY type STRING
    returning
      value(R_NEW_CODE) type STRING .
  methods RFC_API_EXISTS
    returning
      value(RESULT) type ABAP_BOOL .
  methods RFC_API_OBJ_INFO_EXISTS
    returning
      value(RESULT) type ABAP_BOOL .
  methods GET_DDL_DEPENDENCIES
    importing
      !OBJECTNAME type OBJECTNAME
    returning
      value(RESULT) type DDLDEPENDENCY_TAB .
  methods BELONG_REF_OBJ_SAP_OR_PARTN
    importing
      !REF_OBJ_INFO type TY_OBJECT
    returning
      value(RESULT) type ABAP_BOOL .
  methods BELNG_REF_OBJ_CUST_DIFF_DLVU
    importing
      !CHECKED_OBJ_INFO type TY_OBJECT
      !REF_OBJ_INFO type TY_OBJECT
    returning
      value(RESULT) type ABAP_BOOL .
  methods IS_ENQUEUE_DEQUEUE_REPORTED
    importing
      !REF_OBJ_INFO type SYCH_OBJECT_USAGE_ENTRY
    returning
      value(RESULT) type ABAP_BOOL .
  methods DO_CHECK
    importing
      !I_ROOT_OBJECT type SYCH_OBJECT_ENTRY
      !I_USAGES type SYCH_OBJECT_USAGE
    returning
      value(R_ERRORS) type SYCH_OBJECT_USAGE .
ENDCLASS.



CLASS ZCL_CCM_CLS_CI_CHECK_ENV IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->ADJUST_FUNC_ERRORS
* +-------------------------------------------------------------------------------------------------+
* | [<-->] C_ERRORS                       TYPE        SYCH_OBJECT_USAGE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method ADJUST_FUNC_ERRORS.

    data l_funcname type funcname.
    data group type rs38l-area.

    " treat FUNCs in special way
    loop at c_errors assigning field-symbol(<fs_error_func>) where trobjtype = 'FUNC'.

      l_funcname = <fs_error_func>-sobj_name.

      if l_funcname(8) = 'ENQUEUE_' or l_funcname(8) = 'DEQUEUE_'.
        <fs_error_func>-trobjtype   = 'ENQU'.
        <fs_error_func>-sobj_name   = l_funcname+8.
        <fs_error_func>-object_type = 'FUNC'.
        <fs_error_func>-sub_key     = l_funcname.
        continue.
      endif.

      clear group.

      call function 'FUNCTION_EXISTS' destination l_destination
        exporting
          funcname           = l_funcname
        importing
          group              = group
        exceptions
          function_not_exist = 1
          others             = 2.

      if sy-subrc <> 0.
        continue.
      else.
        <fs_error_func>-object_type = <fs_error_func>-trobjtype.
        <fs_error_func>-sobj_name   = group.
        <fs_error_func>-sub_key     = l_funcname.

        if group(1) = 'X' or group+1 cs '/X'.
          <fs_error_func>-trobjtype = 'FUGS'.
        else.
          <fs_error_func>-trobjtype = 'FUGR'.
        endif.
      endif.
    endloop.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->BELNG_REF_OBJ_CUST_DIFF_DLVU
* +-------------------------------------------------------------------------------------------------+
* | [--->] CHECKED_OBJ_INFO               TYPE        TY_OBJECT
* | [--->] REF_OBJ_INFO                   TYPE        TY_OBJECT
* | [<-()] RESULT                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method BELNG_REF_OBJ_CUST_DIFF_DLVU.
    result = abap_false.

    " referenced object is within checkable namespaces but in different SW component
    if ( checkable_namespaces is not initial ) and
       ( line_exists( checkable_namespaces[ table_line = ref_obj_info-namespace ] )  ) and
       ( ref_obj_info-dlvunit <> checked_obj_info-dlvunit ).
      result = abap_true.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->BELONG_REF_OBJ_SAP_OR_PARTN
* +-------------------------------------------------------------------------------------------------+
* | [--->] REF_OBJ_INFO                   TYPE        TY_OBJECT
* | [<-()] RESULT                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method BELONG_REF_OBJ_SAP_OR_PARTN.
    result = abap_false.

    " referenced object is NOT within checkable namespaces => SAP or partner
    if ( checkable_namespaces is not initial ) and
       ( not line_exists( checkable_namespaces[ table_line = ref_obj_info-namespace ] ) ).
      result = abap_true.
    endif.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method CONSTRUCTOR.

    super->constructor( ).

** Begin of Change
*    description = 'Check Usage of Released Objects'(000).
    description = 'Check Usage of Released Objects for Custom GTS Simplification Check'.
** End of Change
    category  = 'CL_CI_CATEGORY_CLOUD_READINESS'.
    version   = '000'.
    position  = '004'.

    remote_rfc_enabled  = abap_true.
    has_attributes      = abap_true.
    uses_checksum       = abap_true.
    check_scope_enabled = abap_true.
    has_documentation   = abap_true.

    add_obj_type( gc_object_type_prog ).
    add_obj_type( gc_object_type_reps ).
    add_obj_type( gc_object_type_clas ).
    add_obj_type( gc_object_type_intf ).
    add_obj_type( gc_object_type_fugr ).
    add_obj_type( gc_object_type_fugs ).
    add_obj_type( gc_object_type_fugx ).
    add_obj_type( gc_object_type_func ).

    add_obj_type( gc_object_type_dial ).
    add_obj_type( gc_object_type_type ).
    add_obj_type( gc_object_type_ldba ).
    add_obj_type( gc_object_type_wdyn ).

    add_obj_type( gc_object_type_doma ).
    add_obj_type( gc_object_type_dtel ).
    add_obj_type( gc_object_type_tabl ).
    add_obj_type( gc_object_type_ttyp ).
    add_obj_type( gc_object_type_view ).
    add_obj_type( gc_object_type_shlp ).
    add_obj_type( gc_object_type_enqu ).
    add_obj_type( gc_object_type_sqlt ).
    add_obj_type( gc_object_type_sqsc ).
    add_obj_type( gc_object_type_auth ).
    add_obj_type( gc_object_type_suso ).
    add_obj_type( gc_object_type_ddls ).
    add_obj_type( gc_object_type_stob ).

    add_obj_type( gc_object_type_tran ).
    add_obj_type( 'ENHO' ).  " only in relation to BAdI

    clear smsg.
    smsg-test = me->myname.
    smsg-code = cl_cls_ci_result_environment=>co_text_forbidden.
    smsg-kind = 'E'.
    smsg-text = 'Usage of not released ABAP Platform APIs'(009).
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

    clear smsg.
    smsg-test = me->myname.
    smsg-code = cl_cls_ci_result_environment=>co_technology_forbidden.
    smsg-kind = 'E'.
    smsg-text = 'Usage of not supported technology'(002).
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

    clear smsg.
    smsg-test = me->myname.
    smsg-code = cl_cls_ci_result_environment=>co_text_forbidden_appl.
    smsg-kind = 'E'.
    smsg-text = 'Usage of not released application API'(006).
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

    clear smsg.
    smsg-test = me->myname.
    smsg-code = cl_cls_ci_result_environment=>co_text_forbidden_ui.
    smsg-kind = 'E'.
    smsg-text = 'Usage of not released API from SAP UI layer'(018).
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

    clear smsg.
    smsg-test = me->myname.
    smsg-code = cl_cls_ci_result_environment=>co_text_diff_cust_swc.
    smsg-kind = 'W'.
    smsg-text = 'Usage of object in other customer software component'(007).
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

    clear smsg.
    smsg-test = me->myname.
    smsg-code = cl_cls_ci_result_environment=>co_text_deprecated.
    smsg-kind = 'W'.
    smsg-text = 'Usage of deprecated API'(004).
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

    clear smsg.
    smsg-test = me->myname.
    smsg-code = me->mcode_not_to_rel.
    smsg-kind = 'E'.
    smsg-text = 'Usage of API that will not be released'(023).
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

    clear smsg.
    smsg-test = me->myname.
    smsg-code = mcode___fulln_error__.
    smsg-kind = 'E'.
    smsg-text = 'Fullname &1 was not resolved in include &2'(099).
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

    mtext___rfc_error__ = 'Function module &1 does not exist in checked system, implement latest version of note 2270689 there'(098).
    clear smsg.
    smsg-test = me->myname.
    smsg-code = mcode___rfc_error__.
    smsg-kind = c_info.
    smsg-category = c_cat_check_part_not_exec.
    smsg-text = mtext___rfc_error__.
    smsg-pcom = c_exceptn_imposibl.
    insert smsg into table scimessages.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHECK_ENV->CREATE_QUICKFIXES
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_USAG                         TYPE        CL_CLS_CI_CHECK_ENVIRONMENT=>TY_STATIC_REF_INFO_COMPLETE
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [--->] I_REF_OBJECT_TYPE              TYPE        TROBJTYPE
* | [--->] I_PROC_DEF                     TYPE        CL_ABAP_COMP_PROCS=>T_PROC_ENTRY
* | [--->] IS_RELEVANT_STATEMENT          TYPE        CL_ABAP_COMP_PROCS=>T_STMT
* | [<-->] CT_DETAILS                     TYPE        SCIT_DETAIL
* | [<-->] CT_QUICKFIXES                  TYPE        CL_CI_QUICKFIX_CREATION=>T_QUICKFIXES
* | [!CX!] CX_CI_QUICKFIX_FAILED
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method CREATE_QUICKFIXES.
    data new_code type string.
    data replacement type ty_successor.

    check ( i_ref_object_type is not initial and i_ref_object_name is not initial ).
    check i_ref_object_type = 'DTEL'.

    if i_ref_object_type = 'STOB'.
      data(l_object_type) = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
    elseif i_ref_object_type = 'BADI'.
      l_object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition.
    else.
      l_object_type = i_ref_object_type.
    endif.

    replacement = get_successor(
      i_ref_object_name = i_ref_object_name
      i_object_type     = l_object_type ).

    if replacement is not initial and replacement-successor_object_type = l_object_type.
      read table is_relevant_statement-tokens assigning field-symbol(<fs_token>)
        with key line   = i_usag-obj_row
                 column = i_usag-obj_column.

      if ( sy-subrc = 0 ).
        data(from_token_idx) = sy-tabix.
        data(old_token)      = is_relevant_statement-tokens[ from_token_idx ]-str.
        data(successor_key)  = conv string( replacement-successor_object_key ).

        new_code = get_new_code(
              i_ref_object_name = i_ref_object_name
              i_old_token       = old_token
              i_successor_key   = successor_key ).

        if ( new_code is not initial ).
          try.
              if me->quickfix_factory is initial.
                quickfix_factory = cl_ci_quickfix_creation=>create_quickfix_alternatives( ).
              endif.

              " Single token replacement => Single Token context
              data(lo_abap_context) = cl_ci_quickfix_abap_context=>create_from_comp_procs_tokens( p_proc_def    = i_proc_def
                                                                                                  p_proc_defs   = proc_defs
                                                                                                  p_from_token  = from_token_idx
                                                                                                  p_action_stmt = is_relevant_statement ).

              data(quickfix) = quickfix_factory->create_quickfix( p_quickfix_code = 'REPL_W_WL' ).

              quickfix->if_ci_quickfix_abap_actions~replace_by( p_new_code = new_code
                                                                p_context  = lo_abap_context ).

              quickfix->add_docu_from_msgclass( p_msg_class      = 'CLS_CHECK_ENVIRONM'
                                                p_msg_number     = '001'
                                                p_msg_parameter1 = l_object_type
                                                p_msg_parameter2 = i_ref_object_name
                                                p_msg_parameter3 = replacement-successor_object_type
                                                p_msg_parameter4 = replacement-successor_object_key(50) ).

              quickfix->enable_automatic_execution( ).

              ct_quickfixes = get_quickfixes( ).

              if lines( ct_quickfixes ) <> 0.
                insert value #( name  = 'QUICKFIXES'
                                value = ref #( ct_quickfixes )  ) into table ct_details.
              else.
                quickfix->disable( ).
              endif.

            catch cx_ci_quickfix_failed  ##NO_HANDLER.
              return.
          endtry.
        endif.
      endif.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->DETERMINE_CHECKSUM_NON_SRC
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_REF_OBJECT_TYPE              TYPE        TROBJTYPE
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [<-()] R_CHECKSUM                     TYPE        SCI_CRC64
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method DETERMINE_CHECKSUM_NON_SRC.

    if i_ref_object_type is not initial and i_ref_object_name is not initial.

      cl_ci_provide_checksum=>gen_chksum_from_chars( exporting p_param     = i_ref_object_type
                                                     changing  p_crc_value = r_checksum
                                                     exceptions parameter_error = 1
                                                                others          = 2 ).
      if sy-subrc = 0.
        cl_ci_provide_checksum=>gen_chksum_from_chars( exporting p_param     = i_ref_object_name
                                                       changing  p_crc_value = r_checksum
                                                       exceptions parameter_error = 1
                                                                  others          = 2 ).
      endif.

      if sy-subrc <> 0.
        r_checksum-i1 = -1.
      endif.
    else.
      r_checksum-i1 = -1.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHECK_ENV->DETERMINE_FINDING_CODE
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_APPLICATION_COMPONENT        TYPE        DF14L-PS_POSID
* | [--->] I_SOFTWARE_COMPONENT           TYPE        DLVUNIT
* | [--->] I_OBJECT_TYPE                  TYPE        TROBJTYPE
* | [--->] I_OBJECT_NAME                  TYPE        SOBJ_NAME
* | [--->] I_ERR_ENTRY                    TYPE        SYCH_OBJECT_USAGE_ENTRY
* | [<-()] R_CODE                         TYPE        SCI_ERRC
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method DETERMINE_FINDING_CODE.
    clear r_code.

    if i_object_type = 'STOB' or i_err_entry-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
      data(l_object_type) = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
      data(l_object_name) = i_err_entry-sub_key.
    elseif i_object_type = 'BADI' or i_err_entry-object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition.
      l_object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition.
      l_object_name = i_err_entry-sub_key.
    else.
      l_object_type = i_object_type.
      l_object_name = i_object_name.
    endif.

    if pa_vrs_2_key_usr <> space.
      select single state from ars_apis_released_for_c1 where object_type = @l_object_type and
                                                               object_key  = @l_object_name
                                                         into  @data(release_state).
    else.
      select single state from ars_apis_released_for_c1_scp where object_type = @l_object_type and
                                                                  object_key  = @l_object_name
                                                            into  @release_state.
    endif.

    if release_state = if_ars_api_constants=>cs_state-deprecated.
      r_code = cl_cls_ci_result_environment=>co_text_deprecated.
    else.
      " not_released flavours
      if i_software_component = 'SAP_BASIS' or i_software_component = 'SAP_ABA' or
         i_software_component = 'SAP_GWFND' .
        r_code = cl_cls_ci_result_environment=>co_text_forbidden.
      elseif i_software_component = 'SAP_UI'.
        r_code = cl_cls_ci_result_environment=>co_text_forbidden_ui.
      else.
        r_code = cl_cls_ci_result_environment=>co_text_forbidden_appl.
      endif.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->DETERMINE_STATIC_REFS
* +-------------------------------------------------------------------------------------------------+
* | [<---] R_SREFS_FULLNAMES              TYPE        CL_YCM_FULLNAME_PROCESSOR=>TTY_FULLNAMES
* | [<---] R_SREFS_PROGRAM_COMPLETE       TYPE        TY_STATIC_REFS_INFO_COMPLETE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method DETERMINE_STATIC_REFS.

    loop at me->proc_defs assigning field-symbol(<l_proc_def>) where proc_id-program = program_name.
      extract_srefs_comp_proc_def(
        exporting
          p_proc_def      =  <l_proc_def>
        importing
          result          = data(srefs_fullnames)
          result_complete = data(srefs_procedure_complete)
      ).
      append lines of srefs_fullnames          to r_srefs_fullnames.
      append lines of srefs_procedure_complete to r_srefs_program_complete.
    endloop.

    sort r_srefs_fullnames.
    delete adjacent duplicates from r_srefs_fullnames.

    " report once per referenced object, include, statement index
    sort r_srefs_program_complete by target_full_name obj_include stmt_index.
    delete adjacent duplicates from r_srefs_program_complete comparing target_full_name obj_include stmt_index.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->DO_CHECK
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_ROOT_OBJECT                  TYPE        SYCH_OBJECT_ENTRY
* | [--->] I_USAGES                       TYPE        SYCH_OBJECT_USAGE
* | [<-()] R_ERRORS                       TYPE        SYCH_OBJECT_USAGE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method DO_CHECK.
    if pa_vrs_2_key_usr <> space.
      do_uc2check(
        exporting
          i_root_object = i_root_object
          i_usages      = i_usages
        receiving
          r_errors      = r_errors
      ).
    else.
      do_uc5check(
         exporting
           i_root_object = i_root_object
           i_usages      = i_usages
         receiving
           r_errors      = r_errors
       ).
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHECK_ENV->DO_UC2CHECK
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_ROOT_OBJECT                  TYPE        SYCH_OBJECT_ENTRY
* | [--->] I_USAGES                       TYPE        SYCH_OBJECT_USAGE
* | [<-()] R_ERRORS                       TYPE        SYCH_OBJECT_USAGE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method DO_UC2CHECK.

    clear: r_errors, me->api_messages.

    cl_cls_api_abap_obj_uc2check=>if_abap_object_check~check(
         exporting
           p_version      = '2'                  " means PROGDIR-UCCHECK = 2
           p_root_object  = i_root_object
           p_object_usage = i_usages
         importing
           p_messages     = data(lt_messages) ). " new relevant result

    me->api_messages = lt_messages.

    loop at lt_messages reference into data(lr_message). " where message->msgty = 'E'.
      insert value #(
        object_key = lr_message->object_key
        info       = lr_message->info
                     ) into table r_errors.
    endloop.


  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHECK_ENV->DO_UC5CHECK
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_ROOT_OBJECT                  TYPE        SYCH_OBJECT_ENTRY
* | [--->] I_USAGES                       TYPE        SYCH_OBJECT_USAGE
* | [<-()] R_ERRORS                       TYPE        SYCH_OBJECT_USAGE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method DO_UC5CHECK.
    clear: r_errors, me->api_messages.

    cl_cls_api_abap_obj_uc5check=>if_abap_object_check~check(
         exporting
           p_version      = '5'                  " means PROGDIR-UCCHECK = 5
           p_root_object  = i_root_object
           p_object_usage = i_usages
         importing
*           p_errors       = r_errors ).         " obsolet
           p_messages     = data(lt_messages) ). " new relevant result

    me->api_messages = lt_messages.

    loop at lt_messages reference into data(lr_message). " where message->msgty = 'E'.
      insert value #(
        object_key = lr_message->object_key
        info       = lr_message->info
                     ) into table r_errors.
    endloop.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->EXTRACT_SREFS_COMP_PROC_DEF
* +-------------------------------------------------------------------------------------------------+
* | [--->] P_PROC_DEF                     TYPE        CL_ABAP_COMP_PROCS=>T_PROC_ENTRY
* | [<---] RESULT                         TYPE        CL_YCM_FULLNAME_PROCESSOR=>TTY_FULLNAMES
* | [<---] RESULT_COMPLETE                TYPE        TY_STATIC_REFS_INFO_COMPLETE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method EXTRACT_SREFS_COMP_PROC_DEF.
    data sref            like line of result.
    data sref_complete   like line of result_complete.

    clear: result, result_complete.

    loop at p_proc_def-stmts assigning field-symbol(<l_stmt>).
      clear: sref, sref_complete.

      sref_complete-stmt_index       = sy-tabix.
      get reference of p_proc_def into sref_complete-proc_entry.
      sref_complete-obj_include      = <l_stmt>-include.

      loop at <l_stmt>-tokens assigning field-symbol(<l_token>) where refs is not initial.
        sref_complete-obj_row          = <l_token>-line.
        sref_complete-obj_column       = <l_token>-column.

        " get referenced artifacts

        loop at <l_token>-refs assigning field-symbol(<l_ref_token>).
          check ( strlen( <l_ref_token>-full_name ) >= 4 and <l_ref_token>-full_name(4) <> '\PT:' ).  " predefined type
          check ( strlen( <l_ref_token>-full_name ) >= 4 and <l_ref_token>-full_name(4) <> '\PD:' ).  " predefined data

          check ( not ( <l_ref_token>-full_name eq `\TY:SYST` or <l_ref_token>-full_name cp `\TY:SYST\*` or
                        <l_ref_token>-full_name eq `\DA:SYST` or <l_ref_token>-full_name cp `\DA:SYST\*` ) ).

          check ( not ( <l_ref_token>-full_name eq `\TY:SY` or <l_ref_token>-full_name cp `\TY:SY\*` or
                        <l_ref_token>-full_name eq `\DA:SY` or <l_ref_token>-full_name cp `\DA:SY\*` ) ).

          " this IF deals with indirect usages that have to be ignored
          data(l_index) = sy-tabix + 1.
          if ( lines( <l_token>-refs ) >= l_index ) and not ( line_exists( <l_token>-refs[ tag = 'MA' ] ) ).
            read table <l_token>-refs assigning field-symbol(<l_ref_token_next>) index l_index.

            if sy-subrc = 0 and ( <l_ref_token_next>-tag = <l_ref_token>-tag  and <l_ref_token_next>-column = <l_ref_token>-column and
                                  <l_ref_token_next>-role = <l_ref_token>-role ).
              split <l_ref_token>-full_name      at ':' into table data(itab_ref).
              data(l_itab_ref) = lines( itab_ref ).
              split <l_ref_token_next>-full_name at ':' into table data(itab_ref_next).
              data(l_itab_ref_next) = lines( itab_ref_next ).
              if itab_ref[ l_itab_ref ] = itab_ref_next[ l_itab_ref_next ].
                continue. " same tag, column, role and name(!) => take always the last refs-entry according compiler expert
              endif.
            endif.
          endif.

          if <l_ref_token>-role is initial or ( <l_ref_token>-tag = 'DA' and <l_ref_token>-role = 'j' ).
            " as a formal parameter is not relevant for release
            continue.
          endif.

          append <l_ref_token>-full_name to result.

*          sref_complete-target_full_name = <l_ref_token>-full_name.

          me->get_upcasted_fullname(
            exporting
              fullname          = <l_ref_token>-full_name
          importing
            fullname_upcasted = sref_complete-target_full_name    ).

          append sref_complete to result_complete.
        endloop.
      endloop.
    endloop.

    sort result.
    delete adjacent duplicates from result.

    " report once per referenced object, include, statement index
    sort result_complete by target_full_name obj_include stmt_index.
    delete adjacent duplicates from result_complete comparing target_full_name obj_include stmt_index.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->FILL_DETAILS
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_REF_OBJECT_TYPE_REF          TYPE REF TO TROBJTYPE
* | [--->] I_REF_OBJECT_NAME_REF          TYPE REF TO SOBJ_NAME
* | [--->] I_APPLICATION_COMPONENT_REF    TYPE REF TO DF14L-PS_POSID
* | [--->] I_MESSAGE                      TYPE        SYMSG
* | [--->] I_DEVCLASS_REF                 TYPE REF TO DEVCLASS
* | [--->] I_SOFTWARE_COMPONENT_REF       TYPE REF TO DLVUNIT
* | [--->] I_ADDITIONAL_INFO              TYPE REF TO STRING(optional)
* | [<-()] R_DETAILS                      TYPE        SCIT_DETAIL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method FILL_DETAILS.

    data detail type scis_detail.

    clear r_details.

    detail-name  = 'APPLICATION_COMPONENT'.
    detail-value = i_application_component_ref.
    insert detail into table r_details.

    detail-name  = 'REF_OBJ_TYPE'.
    detail-value = i_ref_object_type_ref.
    insert detail into table r_details.

    detail-name  = 'REF_OBJ_NAME'.
    detail-value = i_ref_object_name_ref.
    insert detail into table r_details.

    detail-name  = 'MESSAGE'.
    detail-value = ref #( i_message ).
    insert detail into table r_details.

    detail-name = 'REF_PACKAGE'.
    detail-value = i_devclass_ref.
    insert detail into table r_details.

    detail-name = 'REF_SOFTWARE_COMPONENT'.
    detail-value = i_software_component_ref.
    insert detail into table r_details.

    if i_additional_info is supplied.
      detail-name  = 'ADD_INFO'.
      detail-value = i_additional_info.
      insert detail into table r_details.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->FILL_ENVIRONMENT_TYPES
* +-------------------------------------------------------------------------------------------------+
* | [<-->] ENVIRONMENT_TYPES              TYPE        ENVI_TYPES
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method FILL_ENVIRONMENT_TYPES.

    data:
      supported_types type cls_object_type_group_elements,
      field_component type string.

    field-symbols: <value> type any.

    supported_types = cl_cls_api_type_support=>get_supported_types( ).

    loop at supported_types assigning field-symbol(<type>) where type+4(1) is initial.
      field_component = 'ENVIRONMENT_TYPES-' && <type>-type.
      assign (field_component) to <value>.
      check sy-subrc = 0.
      <value> = abap_true.
    endloop.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->GET_ATTRIBUTES
* +-------------------------------------------------------------------------------------------------+
* | [<-()] P_ATTRIBUTES                   TYPE        XSTRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_ATTRIBUTES.

    export
       vrs_2     = pa_vrs_2_key_usr
       vrs_5     = pa_vrs_5_abap_cp
     to data buffer p_attributes.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->GET_DDL_DEPENDENCIES
* +-------------------------------------------------------------------------------------------------+
* | [--->] OBJECTNAME                     TYPE        OBJECTNAME
* | [<-()] RESULT                         TYPE        DDLDEPENDENCY_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_DDL_DEPENDENCIES.
    clear result.
    call function 'RS_ABAP_GET_DDL_DEPENDENCIES_E' destination l_destination
      exporting
        p_objectname          = objectname
      tables
        p_dependencies        = result
      exceptions
        not_found             = 1
        communication_failure = 2
        system_failure        = 3
        others                = 4 ##FM_SUBRC_OK.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->GET_DETAIL
* +-------------------------------------------------------------------------------------------------+
* | [--->] P_DETAIL_PACKED                TYPE        XSTRING
* | [<---] P_DETAIL                       TYPE        SCIT_DETAIL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_DETAIL.
    data: detail                 type scis_detail,
          application_component  type ref to ufps_posid,
          ref_obj_type           type ref to trobjtype,
          ref_obj_name           type ref to trobj_name,
          message                type ref to symsg,
          quickfixes             type ref to cl_ci_quickfix_creation=>t_quickfixes,
          ref_package            type ref to devclass,
          ref_software_component type ref to dlvunit,
          ref_add_info           type ref to string.

    clear p_detail[].
    check p_detail_packed is not initial.

    create data: application_component,
                 ref_obj_type,
                 ref_obj_name,
                 message,
                 quickfixes,
                 ref_package,
                 ref_software_component,
                 ref_add_info.

    import application_component  = application_component->*
           ref_obj_type           = ref_obj_type->*
           ref_obj_name           = ref_obj_name->*
           message                = message->*
           quickfixes             = quickfixes->*
           ref_package            = ref_package->*
           ref_software_component = ref_software_component->*
           add_info               = ref_add_info->*
      from data buffer p_detail_packed.

    if application_component->* is not initial.
      detail-name  = 'APPLICATION_COMPONENT'.    " Has to be upper case
      detail-value = application_component.
      insert detail into table p_detail.
    endif.

    if ref_obj_type->* is not initial.
      detail-name  = 'REF_OBJ_TYPE'.             " Has to be upper case
      detail-value = ref_obj_type.
      insert detail into table p_detail.
    endif.

    if ref_obj_name->* is not initial.
      detail-name  = 'REF_OBJ_NAME'.             " Has to be upper case
      detail-value = ref_obj_name.
      insert detail into table p_detail.
    endif.

    if message->* is not initial.
      detail-name  = 'MESSAGE'.                  " Has to be upper case
      detail-value = message.
      insert detail into table p_detail.
    endif.

    if quickfixes->* is not initial.
      detail-name  = 'QUICKFIXES'.               " Has to be upper case
      detail-value = quickfixes.
      insert detail into table p_detail.
    endif.

    if ref_package->* is not initial.
      detail-name  = 'REF_PACKAGE'.    " Has to be upper case
      detail-value = ref_package.
      insert detail into table p_detail.
    endif.

    if ref_software_component->* is not initial.
      detail-name  = 'REF_SOFTWARE_COMPONENT'.    " Has to be upper case
      detail-value = ref_software_component.
      insert detail into table p_detail.
    endif.

    if ref_add_info->* is not initial.
      detail-name  = 'ADD_INFO'.    " Has to be upper case
      detail-value = ref_add_info.
      insert detail into table p_detail.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->GET_NEW_CODE
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [--->] I_OLD_TOKEN                    TYPE        CL_ABAP_COMP_PROCS=>T_TOKEN-STR
* | [--->] I_SUCCESSOR_KEY                TYPE        STRING
* | [<-()] R_NEW_CODE                     TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_NEW_CODE.

    clear r_new_code.

    check i_successor_key is not initial.

    if ( i_old_token = i_ref_object_name ).
      r_new_code  = i_successor_key.
*    else.
*      " due to potentially syntax-errors we decided to not offer QF in such situation
*      find all occurrences of i_ref_object_name in i_old_token results data(result_tab).
*      if lines( result_tab ) = 1.
*        " easy stuff: single occurrence of i_ref_object_name to be replaced, just replace
*        r_new_code = replace( val = i_old_token sub = i_ref_object_name with = i_successor_key ).
*      else.
*        " multiple occurrences: check chars before and after i_ref_object_name in old_token
*        " deal with method-call token like 'my_if_xyz_inst->if_xyz~m1('  and replace the right 'if_xyz'
*        loop at result_tab assigning field-symbol(<fs_result>).
*          data(l_occurrence) = sy-tabix.
*          data(l_after)      = substring_after( val = i_old_token sub = i_ref_object_name occ = l_occurrence ).
*          data(l_before)     = substring_before( val = i_old_token sub = i_ref_object_name occ = l_occurrence ).
*          data(l_lenb)       = strlen( l_before ) - 1.
*          if ( l_before is initial or ( l_lenb > 0 and l_before+l_lenb(1) = '>') ) and
*             ( l_after is initial or ( l_after(1) = '-'  or l_after(1) = '=' or l_after(1) = '~' or l_after(1) = '(' ) ).
*            r_new_code = replace( val = i_old_token sub = i_ref_object_name with = i_successor_key occ = l_occurrence ).
*          endif.
*        endloop.
*      endif.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->GET_RESULT_NODE
* +-------------------------------------------------------------------------------------------------+
* | [--->] P_KIND                         TYPE        SYCHAR01
* | [<-()] P_RESULT                       TYPE REF TO CL_CI_RESULT_ROOT
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_RESULT_NODE.
    create object p_result type cl_cls_ci_result_environm_new
      exporting
        p_kind = p_kind.

*    create object p_result type cl_cls_ci_result_environment
*      exporting
*        p_kind = p_kind.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHECK_ENV->GET_SUCCESSOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [--->] I_OBJECT_TYPE                  LIKE        IF_ARS_ABAP_OBJECT_CHECK=>GC_SUB_OBJECT_TYPE-CDS_ENTITY
* | [<-()] R_REPLACEMENT                  TYPE        TY_SUCCESSOR
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_SUCCESSOR.

    if pa_vrs_2_key_usr <> space.
      select single from ars_apis_released_for_c1
       fields successor_classification, successor_object_type, successor_object_key
       where object_type              = @i_object_type
         and object_key               = @i_ref_object_name
         and successor_classification = 1                 " exactly one successor
       into @r_replacement.
    else.
      select single from ars_apis_released_for_c1_scp
        fields successor_classification, successor_object_type, successor_object_key
        where object_type              = @i_object_type
          and object_key               = @i_ref_object_name
          and successor_classification = 1                 " exactly one successor
        into @r_replacement.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->GET_UPCASTED_FULLNAME
* +-------------------------------------------------------------------------------------------------+
* | [--->] FULLNAME                       TYPE        STRING
* | [<---] FULLNAME_UPCASTED              TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_UPCASTED_FULLNAME.

    clear fullname_upcasted.

    split fullname at ':' into data(kind) data(root).
    split root at '\' into root data(dummy) ##NEEDED.
    fullname_upcasted = |{ kind }:{ root }|.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->IF_CI_TEST~QUERY_ATTRIBUTES
* +-------------------------------------------------------------------------------------------------+
* | [--->] P_DISPLAY                      TYPE        FLAG (default =' ')
* | [--->] P_IS_ADT                       TYPE        ABAP_BOOL (default =ABAP_FALSE)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method IF_CI_TEST~QUERY_ATTRIBUTES.

    data:
      l_attributes type sci_atttab,
      l_attribute  like line of l_attributes,
      l_ok         type flag.

    define fill_att.
      get reference of &1 into l_attribute-ref.
      l_attribute-text = &2.
      l_attribute-kind = &3.
      append l_attribute to l_attributes.
    end-of-definition.

    define fill_att_rb.                     " radio button
      get reference of &1 into l_attribute-ref.
      l_attribute-text = &2.
      l_attribute-kind = &3.
      l_attribute-button_group = &4.
      l_attribute-id = &5.
      append l_attribute to l_attributes.
    end-of-definition.

    fill_att sy-index              'ABAP Language Version'(010)           'G'        ##TEXT_DIFF.

    fill_att_rb pa_vrs_5_abap_cp   'ABAP for Cloud Development'(015)      'R' 'MSGF' 'ABAPLanguageVersion' ##TEXT_DIFF.
    fill_att_rb pa_vrs_2_key_usr   'ABAP for Key Users'(012)              'R' 'MSGF' '1234' ##TEXT_DIFF.

    l_ok = ''.

    while l_ok = ''.
      data(l_popup_canceled) = cl_ci_query_attributes=>generic( p_name = myname
                                                                p_title      = text-000
                                                                p_attributes = l_attributes
                                                                p_display    = p_display ).
      if l_popup_canceled = abap_true.
        return.
      endif.

      attributes_ok    = 'X'.

      if p_display = 'X'.
        " in display mode => go out
        return.
      endif.

      l_ok = 'X'.

    endwhile.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->IS_ENQUEUE_DEQUEUE_REPORTED
* +-------------------------------------------------------------------------------------------------+
* | [--->] REF_OBJ_INFO                   TYPE        SYCH_OBJECT_USAGE_ENTRY
* | [<-()] RESULT                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method IS_ENQUEUE_DEQUEUE_REPORTED.
    result = abap_false.

    if ref_obj_info-object_type = 'FUNC' and ( ref_obj_info-sub_key(8) = 'ENQUEUE_' or ref_obj_info-sub_key(8) = 'DEQUEUE_' ).
      result = abap_true.
    endif.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->LOAD_CHNG_SIDBDET_FROM_GIT
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_GIT_URL                      TYPE        SYCM_URL(optional)
* | [<-()] RS_OBJ_SIDBCHNG_DET_FRM_GIT    TYPE        TY_OBJ_DET_FULL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD load_chng_sidbdet_from_git.

    IF ms_obj_chng_det_frm_cust_sidb IS NOT INITIAL.
      rs_obj_sidbchng_det_frm_git =  ms_obj_chng_det_frm_cust_sidb.
      RETURN.
    ENDIF.

    DATA(l_git_url) = COND sycm_url(
                        WHEN i_git_url IS INITIAL
                          THEN 'https://raw.githubusercontent.com/Sandeep-madhyastha/GtsSIDB/main/GtsSIDBDetails.json'
                        ELSE i_git_url ).

    cl_http_client=>create_by_url(
         EXPORTING
           url                = CONV #( l_git_url )
         IMPORTING
           client             = DATA(lr_http_client)
         EXCEPTIONS
           argument_not_found = 1
           plugin_not_active  = 2
           internal_error     = 3
           OTHERS             = 4 ).

    lr_http_client->send(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2 ).

    lr_http_client->receive(
       EXCEPTIONS
         http_communication_failure = 1
         http_invalid_state         = 2
         http_processing_failed     = 3 ).

      " Assume everything goes fine no exception in case of url fetch!
      " In case of error empty deep structure is returned
      DATA(l_response_json) = lr_http_client->response->get_cdata( ).


    " Convert JSON to ABAP list
    /ui2/cl_json=>deserialize(
      EXPORTING
        json             = l_response_json
      CHANGING
        data             = rs_obj_sidbchng_det_frm_git
    ).

    IF rs_obj_sidbchng_det_frm_git IS NOT INITIAL.
      ms_obj_chng_det_frm_cust_sidb = rs_obj_sidbchng_det_frm_git.
    ENDIF.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->LOOKUP_IN_DDTYPES
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CS_REF                         TYPE        CL_YCM_FULLNAME_PROCESSOR=>TY_ID_MAPPING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method LOOKUP_IN_DDTYPES.

    data l_typename type ddtypes-typename.

    if cs_ref-tadir_obj_name is not initial.
      l_typename = cs_ref-tadir_obj_name.
    else.
      if cs_ref-fullname_upcast is initial.
        get_upcasted_fullname(
          exporting
            fullname          = cs_ref-fullname
          importing
            fullname_upcasted = cs_ref-fullname_upcast ).
      endif.

      l_typename = cs_ref-fullname_upcast+4.

    endif.

    select single typekind typename into ( cs_ref-tadir_obj_type, cs_ref-tadir_obj_name )
                                    from ddtypes where typename = l_typename.

    if sy-subrc <> 0.
      data p_full_name type string.
      data p_obj_type  type trobjtype.
      data p_obj_name  type sobj_name.

      if cs_ref-fullname_upcast is initial.
        get_upcasted_fullname(
          exporting
            fullname          = cs_ref-fullname
          importing
            fullname_upcasted = cs_ref-fullname_upcast ).
      endif.

      p_full_name = cs_ref-fullname_upcast.

      read table ddypes_resolved assigning field-symbol(<fs_ddtypes>) with key fullname = p_full_name.
      if sy-subrc = 0.
        cs_ref-tadir_obj_type = <fs_ddtypes>-obj_type.
        cs_ref-tadir_obj_name = <fs_ddtypes>-obj_name.
      else.
        call function 'RS_ABAP_GET_TYPE_INFO_E' destination l_destination
          exporting
            p_full_name = p_full_name
          importing
            p_obj_type  = p_obj_type
            p_obj_name  = p_obj_name
          exceptions
            not_found   = 1
            others      = 2.
        if sy-subrc = 0.
          if p_obj_type <> 'DOMA'.
            cs_ref-tadir_obj_type = p_obj_type.
            cs_ref-tadir_obj_name = p_obj_name.
            append value ty_ddtypes_resolved( fullname =  p_full_name obj_type = p_obj_type obj_name = p_obj_name ) to ddypes_resolved.
          endif.
        endif.
      endif.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->MAP_WHITELIST_ERR_TO_ALL_POS
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_REFERENCED_OBJECTS           TYPE        CL_YCM_FULLNAME_PROCESSOR=>TTY_ID_MAPPING
* | [--->] I_REF_OBJECT_TYPE              TYPE        TROBJTYPE
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [--->] I_KIND                         TYPE        SYCHAR01
* | [--->] I_CODE                         TYPE        SCI_ERRC
* | [--->] I_APPLICATION_COMPONENT        TYPE        DF14L-PS_POSID
* | [<-->] C_DETAILS                      TYPE        SCIT_DETAIL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method MAP_WHITELIST_ERR_TO_ALL_POS.
    data l_fu_tag    type string value '\FU:'.
    data detail      type scis_detail.
    data l_additional_info   type string.
    data ref_additional_info type ref to string.

    field-symbols <usag>           type cl_cls_ci_check_environment=>ty_static_ref_info_complete.
    field-symbols <l_proc_def>     type cl_abap_comp_procs=>t_proc_entry.
    field-symbols <fs_info_detail> type scis_detail.

    data(l_additional_info_acc)      = c_db_access && 'Table is accessed on database'(017).
    data(l_additional_info_acc_view) = c_db_access && 'View is accessed on database'(021).
    data(l_additional_info_acc_cds)  = c_db_access && 'CDS View is accessed on database'(022).


    if i_ref_object_type = 'FUNC'.
      " \FU:CONVERSION_EXIT_ALPHA_INPUT   e.g.
      loop at me->srefs_program_complete assigning <usag>
                                         where target_full_name = |{ l_fu_tag }{ i_ref_object_name }|.

        " CALL FUNCTION ... DESTINATION <foreign_dest> should not be reported
        assign <usag>-proc_entry->* to <l_proc_def>.
        read table <l_proc_def>-stmts index <usag>-stmt_index assigning field-symbol(<fs_relevant_statement>).
        if sy-subrc = 0.
          read table <fs_relevant_statement>-tokens with key str = 'CALL' transporting no fields.
          if sy-subrc = 0 and sy-tabix = 1.      " first token in statement
            read table <fs_relevant_statement>-tokens with key str = 'FUNCTION' transporting no fields.
            if  sy-subrc = 0 and sy-tabix = 2.   " second token in statement
              read table <fs_relevant_statement>-tokens with key str = 'DESTINATION' transporting no fields.
              if  sy-subrc = 0 and sy-tabix = 4. " fourth token in statement
                read table <fs_relevant_statement>-tokens index 5 assigning field-symbol(<fs_tok_dest>).
                if sy-subrc = 0 and <fs_tok_dest>-str <> '''NONE'''. " fifth token is not NONE => skip finding
                  continue.
                endif.
              endif.
            endif.
          endif.
        endif.

        prepare_and_report(
           exporting
             i_ref_object_type       = i_ref_object_type
             i_ref_object_name       = i_ref_object_name
             i_kind                  = i_kind
             i_code                  = i_code
             i_application_component = i_application_component
             i_usag                  = <usag>
             i_details               = c_details ).
      endloop.
    else.
      " get the fullname for referenced tadir-object and determine usages
      loop at i_referenced_objects assigning field-symbol(<fs_usag_targ>) where tadir_obj_type = i_ref_object_type and
                                                                                tadir_obj_name = i_ref_object_name.
        at new fullname_upcast  ##LOOP_AT_OK.
*          data(l_pattern) = |{ <fs_usag_targ>-fullname_upcast }*|.
          " srefs_program_complete-target_full_name is the upcasted full_name see meth. EXTRACT_SREFS_COMP_PROC_DEF
          loop at me->srefs_program_complete assigning <usag> where target_full_name = <fs_usag_targ>-fullname_upcast.

            clear: l_additional_info, detail.

            if i_ref_object_type = 'TABL' or i_ref_object_type = 'VIEW' or i_ref_object_type = 'STOB'.

              if i_ref_object_type = 'TABL'  and <fs_usag_targ>-fullname_upcast(4) = '\CP:'.
                data(l_pattern_ty) = <fs_usag_targ>-fullname_upcast.
                replace '\CP:' with '\TY:' into l_pattern_ty.
                read table me->srefs_program_complete with key target_full_name = l_pattern_ty stmt_index = <usag>-stmt_index transporting no fields.
                if sy-subrc = 0.
                  continue.
                endif.
              endif.

              assign <usag>-proc_entry->* to <l_proc_def>.
              read table <l_proc_def>-stmts index <usag>-stmt_index assigning <fs_relevant_statement>.
              if sy-subrc = 0.
                read table <fs_relevant_statement>-tokens index 1 assigning field-symbol(<fs_first_tok>).
                if <fs_first_tok>-str = 'OPEN'.
                  read table <fs_relevant_statement>-tokens index 2 assigning field-symbol(<fs_sec_tok>).
                endif.
                if sy-subrc = 0 and ( <fs_first_tok>-str = 'SELECT' or <fs_first_tok>-str = 'UPDATE' or <fs_first_tok>-str = 'DELETE' or
                                      <fs_first_tok>-str = 'INSERT' or <fs_first_tok>-str = 'MODIFY' or
                                      ( <fs_first_tok>-str = 'OPEN' and <fs_sec_tok>-str = 'CURSOR' ) ).

                  if <fs_first_tok>-str = 'UPDATE'.
                    data(sql_analyzer)  = new cl_ci_sql_utilities( ).
                    data(l_update_info) = sql_analyzer->get_update_info( <fs_relevant_statement> ).
                    if l_update_info-target-str = i_ref_object_name.
                      if i_ref_object_type = 'TABL'.
                        l_additional_info = l_additional_info_acc.
                      elseif i_ref_object_type = 'VIEW'.
                        l_additional_info = l_additional_info_acc_view.
                      else.
                        l_additional_info = l_additional_info_acc_cds.
                      endif.
                    endif.
                  elseif <fs_first_tok>-str = 'SELECT'.
                    sql_analyzer = new cl_ci_sql_utilities( ).
                    data(l_select_info) = sql_analyzer->get_select_info( <fs_relevant_statement> ).
                    if l_select_info-source-str = i_ref_object_name or line_exists( l_select_info-join_targets[ str = i_ref_object_name ] ).
                      if i_ref_object_type = 'TABL'.
                        l_additional_info = l_additional_info_acc.
                      elseif i_ref_object_type = 'VIEW'.
                        l_additional_info = l_additional_info_acc_view.
                      else.
                        l_additional_info = l_additional_info_acc_cds.
                      endif.
                    endif.
                  else.
                    " INSERT/DELETE/MODIFY/OPEN CURSOR
                    if i_ref_object_type = 'TABL'.
                      l_additional_info = l_additional_info_acc.
                    elseif i_ref_object_type = 'VIEW'.
                      l_additional_info = l_additional_info_acc_view.
                    else.
                      l_additional_info = l_additional_info_acc_cds.
                    endif.
                  endif.

                  if l_additional_info is not initial.
                    create data ref_additional_info.
                    ref_additional_info->* = l_additional_info.

                    detail-name  = 'ADD_INFO'.
                    detail-value = ref_additional_info.
                    insert detail into table c_details.
                  endif.
                endif.
              endif.
            endif.

            prepare_and_report(
               exporting
                 i_ref_object_type       = i_ref_object_type
                 i_ref_object_name       = i_ref_object_name
                 i_kind                  = i_kind
                 i_code                  = i_code
                 i_application_component = i_application_component
                 i_usag                  = <usag>
                 i_details               = c_details ).

            " remove add_info as next finding might not have it
            if i_ref_object_type = 'TABL' or i_ref_object_type = 'VIEW' or i_ref_object_type = 'STOB'.
              read table c_details with key name = 'ADD_INFO' transporting no fields.
              if sy-subrc = 0.
                delete c_details index sy-tabix.
              endif.
            endif.
          endloop.
        endat.
      endloop.
    endif.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->PREPARE_AND_REPORT
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_REF_OBJECT_TYPE              TYPE        TROBJTYPE
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [--->] I_KIND                         TYPE        SYCHAR01
* | [--->] I_CODE                         TYPE        SCI_ERRC
* | [--->] I_APPLICATION_COMPONENT        TYPE        DF14L-PS_POSID
* | [--->] I_USAG                         TYPE        CL_CLS_CI_CHECK_ENVIRONMENT=>TY_STATIC_REF_INFO_COMPLETE
* | [--->] I_DETAILS                      TYPE        SCIT_DETAIL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PREPARE_AND_REPORT.

    data x_detail      type xstring.
    data l_checksum    type sci_crc64.
    data l_details     like i_details.
    data l_origins     type cl_abap_comp_procs=>t_origins.
    data lt_quickfixes type cl_ci_quickfix_creation=>t_quickfixes.

    field-symbols <l_proc_def> type cl_abap_comp_procs=>t_proc_entry.

    l_details = i_details.

    " checksum consists of: I_REF*, include and <l_proc_def> with stmnt_index
    l_checksum = determine_checksum_non_src(
      exporting
        i_ref_object_type = i_ref_object_type
        i_ref_object_name = i_ref_object_name ).

    cl_ci_provide_checksum=>gen_chksum_from_chars(  exporting p_param          = i_usag-obj_include
                                                    changing  p_crc_value      = l_checksum
                                                    exceptions parameter_error = 1 ).
    assert sy-subrc = 0.
    assign i_usag-proc_entry->* to <l_proc_def>.

    " further enrich l_checksum required by report_finding
    get_stmt_checksum( exporting p_proc_def = <l_proc_def> p_index_stmt = i_usag-stmt_index changing p_checksum = l_checksum ).

    " get finding origins required by report_finding
    read table <l_proc_def>-stmts index i_usag-stmt_index assigning field-symbol(<fs_relevant_statement>).

    loop at <fs_relevant_statement>-links_origins into data(l_link).
      append <l_proc_def>-origins[ l_link ] to l_origins.
    endloop.

    " get quickfix for finding in relevant statement - replace deprecated artifact by released artifact
    create_quickfixes(
        exporting
          i_usag                = i_usag
          i_ref_object_name     = i_ref_object_name
          i_ref_object_type     = i_ref_object_type
          i_proc_def            = <l_proc_def>
          is_relevant_statement = <fs_relevant_statement>
        changing
          ct_details    = l_details
          ct_quickfixes = lt_quickfixes ).

    " get l_details as xstring
    x_detail = export_to_xstring( exporting p_sub_obj_type = me->object_type
                                            p_sub_obj_name = me->object_name
                                            p_line         = i_usag-obj_row
                                            p_column       = i_usag-obj_column
                                            p_kind         = i_kind
                                            p_code         = i_code
                                            p_param_1      = i_ref_object_type
                                            p_param_2      = i_ref_object_name
                                  changing  p_details      = l_details ).

    report_finding(
       i_sub_obj_type    = c_type_include
       i_sub_obj_name    = i_usag-obj_include
       i_detail          = x_detail
       i_ref_object_type = i_ref_object_type
       i_ref_object_name = i_ref_object_name
       i_line            = i_usag-obj_row
       i_column          = i_usag-obj_column
       i_kind            = i_kind
       i_code            = i_code
       i_appl_component  = i_application_component
       i_checksum        = l_checksum
       i_finding_origins = l_origins ).

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->PROCESS_NON_SRCCODE_ARTIFACT
* +-------------------------------------------------------------------------------------------------+
* | [<---] ENVIRONMENT_TAB                TYPE        SENVI_TAB
* | [EXC!] RFC_CALL_ERROR
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PROCESS_NON_SRCCODE_ARTIFACT.
    data msg               type c length 255.
    data environment_types type envi_types.
    data obj_type          type euobj-id.

    obj_type = me->object_type.

    fill_environment_types( changing environment_types = environment_types ).

    call function 'REPOSITORY_ENVIRONMENT_ALL' destination l_destination
      exporting
        obj_type              = obj_type
        object_name           = me->object_name
        deep                  = 1
        environment_types     = environment_types
        aggregate_level       = '1'
      tables
        environment_tab       = environment_tab
      exceptions
        communication_failure = 1 message msg
        system_failure        = 2 message msg
        others                = 3.
    if sy-subrc <> 0.
      if msg is initial.
        msg = 'Function module remote call failure - processing of non-source artifacts fails'(201).
      endif.

      inform( exporting p_test         = me->myname
                        p_sub_obj_type = object_type
                        p_sub_obj_name = object_name
                        p_code         = mcode___rfc_error__
                        p_param_1      = msg
                        p_param_2      = 'REPOSITORY_ENVIRONMENT_ALL'
                        p_checksum_1   = -1 ).
      raise rfc_call_error.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->PROCESS_SRCCODE_ARTIFACT
* +-------------------------------------------------------------------------------------------------+
* | [<---] E_REFERENCED_OBJECTS           TYPE        CL_YCM_FULLNAME_PROCESSOR=>TTY_ID_MAPPING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PROCESS_SRCCODE_ARTIFACT.

    data srefs_fullnames              type cl_ycm_fullname_processor=>tty_fullnames.
    data srefs_fullnames_resolved     type cl_ycm_fullname_processor=>tty_id_mapping.
    data srefs_fullnames_not_resolved type cl_ycm_fullname_processor=>tty_id_mapping.

    data obj_fullname_processor type ref to cl_ycm_fullname_processor.
    field-symbols <fs_ref>      type cl_ycm_fullname_processor=>ty_id_mapping.


    data:
      l_object   type cvs_tadir,
      l_objects  type table of cvs_tadir,
      l_result_x type xstring,
      l_results  type cl_abap_comp_procs=>t_objects_infos,
      msg_rfc    type c length 255.

    clear: e_referenced_objects, me->srefs_program_complete.

    check get( ) = 'X'.

    " read ABAP COMP PROCS information on static references
    load_program_proc_defs( exporting p_program = program_name
                            exceptions others = 1 ).
    if sy-subrc <> 0.
      return.
    endif.

    obj_fullname_processor = cl_ycm_fullname_processor=>create_instance( ).

    determine_static_refs(
      importing
        r_srefs_fullnames        = srefs_fullnames
        r_srefs_program_complete = me->srefs_program_complete ).


    obj_fullname_processor->map_ref_fullnames_to_tadir_ids(
      exporting
        program_name         =    me->program_name
        object_name          =    me->object_name
        object_type          =    me->object_type
        abap_symbol_ref      =    me->symb_ref
        referenced_fullnames =    srefs_fullnames
        condense_mode        =    cl_ycm_fullname_processor=>co_mapping_mode-condense_by_tadir_id
        mapping_mode_4_wl    =    abap_true
      importing
        mapping              =    srefs_fullnames_resolved   ).


    loop at srefs_fullnames_resolved assigning <fs_ref> where processing_status = cl_ycm_fullname_processor=>co_progress-tadir_id_retrieved or
                                                              processing_status = cl_ycm_fullname_processor=>co_progress-initial or
                                                              tadir_obj_type = 'FUXX'.
      case <fs_ref>-tadir_obj_type.
        when 'CLIF' or 'TAVI' or 'DDDT'.
          lookup_in_ddtypes(
             changing
               cs_ref = <fs_ref> ).
          if <fs_ref>-tadir_obj_type = 'CLIF'.
            " no DDTYPES resolution -> still have classes without DDTYPES ....
            select single object from tadir into <fs_ref>-tadir_obj_type where pgmid = 'R3TR' and "#EC CI_NOORDER
                                                                          ( object = 'CLAS' or object = 'INTF' ) and
                                                                            obj_name = <fs_ref>-tadir_obj_name. "#EC CI_GENBUFF
            if sy-subrc <> 0.
              loop at tadir_resolved assigning field-symbol(<fs_tadir_resolved>) where obj_name = <fs_ref>-tadir_obj_name and
                                                                                                 ( object = 'CLAS' or object = 'INTF' ).
                <fs_ref>-tadir_obj_type = <fs_tadir_resolved>-object.
                exit.
              endloop.
              if sy-subrc <> 0.
                append <fs_ref> to srefs_fullnames_not_resolved.

                l_object-object   = 'CLAS'.
                l_object-obj_name = <fs_ref>-tadir_obj_name.
                append l_object to l_objects.

                l_object-object   = 'INTF'.
                append l_object to l_objects.
              endif.
            endif.
          elseif <fs_ref>-tadir_obj_type = 'TAVI'.
            loop at tadir_resolved assigning <fs_tadir_resolved> where obj_name = <fs_ref>-tadir_obj_name and
                                                                       ( object = 'TABL' or object = 'VIEW' ).
              <fs_ref>-tadir_obj_type = <fs_tadir_resolved>-object.
              exit.
            endloop.
            if sy-subrc <> 0.
              append <fs_ref> to srefs_fullnames_not_resolved.

              l_object-object   = 'TABL'.
              l_object-obj_name = <fs_ref>-tadir_obj_name.
              append l_object to l_objects.
              l_object-object   = 'VIEW'.
              append l_object to l_objects.
            endif.
          elseif <fs_ref>-tadir_obj_type = 'DDDT'.
            loop at tadir_resolved assigning <fs_tadir_resolved> where obj_name = <fs_ref>-tadir_obj_name and
                                                                      ( object = 'DTEL' or object = 'TTYP' or object = 'STOB' ).
              <fs_ref>-tadir_obj_type = <fs_tadir_resolved>-object.
              exit.
            endloop.
            if sy-subrc <> 0.
              append <fs_ref> to srefs_fullnames_not_resolved.

              l_object-object   = 'DTEL'.
              l_object-obj_name = <fs_ref>-tadir_obj_name.
              append l_object to l_objects.
              l_object-object   = 'TTYP'.
              append l_object to l_objects.
              l_object-object   = 'STOB'.
              append l_object to l_objects.
            endif.
          endif.
        when 'FUXX'.
          if <fs_ref>-tadir_obj_name(1) = 'X' or <fs_ref>-tadir_obj_name+1 cs '/X' or <fs_ref>-fullname cs ':EXIT_'.
            <fs_ref>-tadir_obj_type = 'FUGS'.
          else.
            <fs_ref>-tadir_obj_type = 'FUGR'.
          endif.
        when 'SUSA'.
          select single object from tadir into <fs_ref>-tadir_obj_type where pgmid = 'R3TR' and "#EC CI_NOORDER
                                                                           ( object = 'SUSO' or object = 'AUTH' ) and
                                                                             obj_name = <fs_ref>-tadir_obj_name. "#EC CI_GENBUFF
          if sy-subrc <> 0.
            loop at tadir_resolved assigning <fs_tadir_resolved> where obj_name = <fs_ref>-tadir_obj_name and ( object = 'SUSO' or
                                                                                                                object = 'AUTH' ).
              <fs_ref>-tadir_obj_type = <fs_tadir_resolved>-object.
              exit.
            endloop.
            if sy-subrc <> 0.

              append <fs_ref> to srefs_fullnames_not_resolved.

              l_object-object   = 'SUSO'.
              l_object-obj_name = <fs_ref>-tadir_obj_name.
              append l_object to l_objects.

              l_object-object   = 'AUTH'.
              append l_object to l_objects.
            endif.
          endif.
        when space.
          if <fs_ref>-fullname+1(2) = 'FU'.
            <fs_ref>-tadir_obj_type = 'FUNC'.
            if <fs_ref>-tadir_obj_name is initial.
              if <fs_ref>-fullname_upcast is initial.
                get_upcasted_fullname(
                  exporting
                    fullname          = <fs_ref>-fullname
                  importing
                    fullname_upcasted = <fs_ref>-fullname_upcast ).
              endif.
              <fs_ref>-tadir_obj_name = <fs_ref>-fullname_upcast+4.
            endif.
          elseif <fs_ref>-fullname_upcast+1(2) = 'TY'.
            lookup_in_ddtypes(
               changing
                 cs_ref = <fs_ref> ).
          endif.
      endcase.

      if ( <fs_ref>-tadir_obj_type is not initial ) and
         ( <fs_ref>-tadir_obj_type <> 'CLIF' and <fs_ref>-tadir_obj_type <> 'TAVI' and <fs_ref>-tadir_obj_type <> 'DDDT' ).

        " has been resolved and has a well defined object type
        append <fs_ref> to e_referenced_objects[].
      endif.
    endloop.

    sort l_objects by object obj_name.
    delete adjacent duplicates from l_objects.

    check l_objects is not initial.

    call function 'RS_ABAP_GET_OBJECTS_INFOS_E' destination l_destination
      importing
        p_results_x           = l_result_x
      tables
        p_objects             = l_objects
      exceptions
        communication_failure = 1 message msg_rfc
        system_failure        = 2 message msg_rfc
        others                = 3.
    if sy-subrc <> 0.
      " no API => no valid results, go out
      inform( exporting p_test         = me->myname
                        p_sub_obj_type = object_type
                        p_sub_obj_name = object_name
                        p_code         = mcode___rfc_error__
                        p_param_1      = msg_rfc
                        p_param_2      = 'RS_ABAP_GET_OBJECTS_INFOS_E'
                        p_checksum_1   = -1 ).
      return.
    else.
      if l_result_x is not initial.
        import results = l_results from data buffer l_result_x.
      endif.
    endif.

    check l_results is not initial.

    append lines of l_results to tadir_resolved.

    loop at srefs_fullnames_not_resolved assigning <fs_ref>.
      case <fs_ref>-tadir_obj_type.
        when 'CLIF'.
          loop at l_results assigning field-symbol(<fs_obj>) where obj_name = <fs_ref>-tadir_obj_name and ( object = 'CLAS' or
                                                                                                            object = 'INTF' ).
            <fs_ref>-tadir_obj_type = <fs_obj>-object.
            append <fs_ref> to e_referenced_objects[].
            exit.
          endloop.
        when 'SUSA'.
          loop at l_results assigning <fs_obj> where obj_name = <fs_ref>-tadir_obj_name and ( object = 'SUSO' or
                                                                                              object = 'AUTH' ).
            <fs_ref>-tadir_obj_type = <fs_obj>-object.
            append <fs_ref> to e_referenced_objects[].
            exit.
          endloop.
        when 'TAVI'.
          loop at l_results assigning <fs_obj> where obj_name = <fs_ref>-tadir_obj_name and ( object = 'TABL' or
                                                                                              object = 'VIEW' ).
            <fs_ref>-tadir_obj_type = <fs_obj>-object.
            append <fs_ref> to e_referenced_objects[].
            exit.
          endloop.
        when 'DDDT'.
          loop at l_results assigning <fs_obj> where obj_name = <fs_ref>-tadir_obj_name and ( object = 'DTEL' or
                                                                                              object = 'TTYP' or object = 'STOB' ).
            <fs_ref>-tadir_obj_type = <fs_obj>-object.
            append <fs_ref> to e_referenced_objects[].
            exit.
          endloop.
        when others.
          continue.
      endcase.
    endloop.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->PUT_ATTRIBUTES
* +-------------------------------------------------------------------------------------------------+
* | [--->] P_ATTRIBUTES                   TYPE        XSTRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PUT_ATTRIBUTES.

    import
       vrs_2     = pa_vrs_2_key_usr
       vrs_5     = pa_vrs_5_abap_cp
     from data buffer p_attributes.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHECK_ENV->REPORT_FINDING
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_SUB_OBJ_TYPE                 TYPE        TROBJTYPE
* | [--->] I_SUB_OBJ_NAME                 TYPE        SOBJ_NAME
* | [--->] I_DETAIL                       TYPE        XSTRING
* | [--->] I_REF_OBJECT_TYPE              TYPE        TROBJTYPE
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [--->] I_LINE                         TYPE        TOKEN_ROW
* | [--->] I_COLUMN                       TYPE        TOKEN_COL
* | [--->] I_KIND                         TYPE        SYCHAR01
* | [--->] I_CODE                         TYPE        SCI_ERRC
* | [--->] I_APPL_COMPONENT               TYPE        DF14L-PS_POSID
* | [--->] I_CHECKSUM                     TYPE        SCI_CRC64
* | [--->] I_FINDING_ORIGINS              TYPE        CL_ABAP_COMP_PROCS=>T_ORIGINS
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method REPORT_FINDING.

    inform(
          exporting p_sub_obj_type    = i_sub_obj_type
                    p_sub_obj_name    = i_sub_obj_name
                    p_code            = i_code
                    p_line            = i_line
                    p_column          = i_column
                    p_kind            = i_kind
                    p_param_1         = i_ref_object_type
                    p_param_2         = i_ref_object_name
                    p_checksum_1      = i_checksum-i1
                    p_test            = me->myname
                    p_detail          = i_detail
                    p_finding_origins = i_finding_origins ).

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->REPORT_FINDING_FOR_NON_SRC
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_REF_OBJECT_TYPE              TYPE        TROBJTYPE
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [--->] I_LINE                         TYPE        TOKEN_ROW
* | [--->] I_COLUMN                       TYPE        TOKEN_COL
* | [--->] I_KIND                         TYPE        SYCHAR01
* | [--->] I_CODE                         TYPE        SCI_ERRC
* | [--->] I_APPLICATION_COMPONENT        TYPE        DF14L-PS_POSID
* | [<-->] C_DETAILS                      TYPE        SCIT_DETAIL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method REPORT_FINDING_FOR_NON_SRC.

    data x_detail type xstring.
    data l_checksum type sci_crc64.
    data l_origins type cl_abap_comp_procs=>t_origins.

    data l_additional_info   type string.
    data ref_additional_info type ref to string.
    data detail              type scis_detail.

    field-symbols <fs_info_detail> type scis_detail.

    if ( object_type = 'VIEW' or object_type = 'DDLS' or object_type = 'STOB' )
       and ( i_ref_object_type = 'TABL' or i_ref_object_type = 'VIEW' or i_ref_object_type = 'STOB' )
       and i_ref_object_name is not initial.

      data(l_additional_info_acc_view) = c_db_access && 'View is accessed on database'(021).   " checked view -> references a TABL
      data(l_additional_info_acc)      = c_db_access && 'Table is accessed on database'(017).
      data(l_additional_info_acc_cds)  = c_db_access && 'CDS View is accessed on database'(022).

      create data ref_additional_info.
      if i_ref_object_type = 'TABL'.
        l_additional_info = l_additional_info_acc.
      elseif i_ref_object_type = 'VIEW'.
        l_additional_info = l_additional_info_acc_view.
      else.
        l_additional_info = l_additional_info_acc_cds.
      endif.

      ref_additional_info->* = l_additional_info.
      detail-name  = 'ADD_INFO'.
      detail-value = ref_additional_info.

      read table c_details assigning <fs_info_detail> with key name = 'ADD_INFO'.
      if sy-subrc <> 0.
        insert detail into table c_details.
      else.
        <fs_info_detail>-value = ref_additional_info.
      endif.
    endif.

    l_checksum = determine_checksum_non_src(
               i_ref_object_type = i_ref_object_type
               i_ref_object_name = i_ref_object_name ).

    x_detail = export_to_xstring( exporting p_sub_obj_type = me->object_type
                                         p_sub_obj_name    = me->object_name
                                         p_line            = i_line
                                         p_column          = i_column
                                         p_kind            = i_kind
                                         p_code            = i_code
                                         p_param_1         = i_ref_object_type
                                         p_param_2         = i_ref_object_name
                               changing  p_details         = c_details ).

    report_finding(
       i_sub_obj_type    = me->object_type
       i_sub_obj_name    = me->object_name
       i_detail          = x_detail
       i_ref_object_type = i_ref_object_type
       i_ref_object_name = i_ref_object_name
       i_line            = i_line
       i_column          = i_column
       i_kind            = i_kind
       i_code            = i_code
       i_appl_component  = i_application_component
       i_checksum        = l_checksum
       i_finding_origins = l_origins ).


    " remove add_info as next finding might not need it
    if l_additional_info is not initial.
      read table c_details with key name = 'ADD_INFO' transporting no fields.
      if sy-subrc = 0.
        delete c_details index sy-tabix.
      endif.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->REPORT_UC5CHECK_ERRORS
* +-------------------------------------------------------------------------------------------------+
* | [--->] REFERENCED_OBJECTS             TYPE        CL_YCM_FULLNAME_PROCESSOR=>TTY_ID_MAPPING
* | [<-->] ERRORS                         TYPE        SYCH_OBJECT_USAGE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD report_uc5check_errors.

    DATA details                    TYPE scit_detail.
    DATA ref_object_type_ref        TYPE REF TO trobjtype.
    DATA ref_object_name_ref        TYPE REF TO sobj_name.
    DATA ref_package_ref            TYPE REF TO devclass.
    DATA ref_software_component_ref TYPE REF TO dlvunit.
    DATA ref_additional_info        TYPE REF TO string.
    DATA ref_object_type            TYPE trobjtype.
    DATA ref_object_name            TYPE sobj_name.
    DATA ref_package                TYPE devclass.
    DATA ref_software_component     TYPE dlvunit.

    DATA line   TYPE token_row.
    DATA column TYPE token_col.
    DATA kind   TYPE sychar01.
    DATA code   TYPE sci_errc.

    DATA application_component      TYPE df14l-ps_posid.
    DATA application_component_ref  TYPE REF TO df14l-ps_posid.
    DATA lt_errors_o                TYPE ty_tab_objects.
    DATA lt_errors                  TYPE sych_object_usage.
    DATA:
      l_object           TYPE cvs_tadir,
      l_objects          TYPE TABLE OF cvs_tadir,
      l_result_x         TYPE xstring,
      l_results          TYPE cl_abap_comp_procs=>t_objects_infos,
      l_result_4_checked LIKE LINE OF l_results,
      msg_rfc            TYPE c LENGTH 255,
      valid_finding      TYPE abap_bool VALUE abap_false,
      msg                TYPE symsg.

    FIELD-SYMBOLS <error_complete> TYPE ty_object.

    CHECK errors IS NOT INITIAL.

    lt_errors = errors.
    SORT lt_errors BY trobjtype sobj_name.

    " errors have no FUGR information, need to add for the select bellow
    adjust_func_errors(
      CHANGING
        c_errors = lt_errors ).

    " get package, software- and application component of checked and referenced object

    " checked object
    l_object-object   = object_type.
    l_object-obj_name = object_name.
    APPEND l_object TO l_objects.

    " referenced objects with errors
    LOOP AT lt_errors ASSIGNING FIELD-SYMBOL(<fs_error>).
      l_object-object   = <fs_error>-trobjtype.
      l_object-obj_name = <fs_error>-sobj_name.
      APPEND l_object TO l_objects.
    ENDLOOP.

    SORT  l_objects BY object obj_name.
    DELETE ADJACENT DUPLICATES FROM l_objects.

    CALL FUNCTION 'RS_ABAP_GET_OBJECTS_INFOS_E' DESTINATION l_destination
      IMPORTING
        p_results_x           = l_result_x
      TABLES
        p_objects             = l_objects
      EXCEPTIONS
        communication_failure = 1 MESSAGE msg_rfc
        system_failure        = 2 MESSAGE msg_rfc
        OTHERS                = 3.
    IF sy-subrc <> 0.
      " no API => no valid results, go out
      inform( EXPORTING p_test         = me->myname
                        p_sub_obj_type = object_type
                        p_sub_obj_name = object_name
                        p_code         = mcode___rfc_error__
                        p_param_1      = msg_rfc
                        p_param_2      = 'RS_ABAP_GET_OBJECTS_INFOS_E'
                        p_checksum_1   = -1 ).
      RETURN.
    ELSE.
      IMPORT results = l_results FROM DATA BUFFER l_result_x.
      TRY.
          l_result_4_checked = l_results[ object = object_type obj_name = object_name ].
          DELETE TABLE l_results FROM l_result_4_checked.
        CATCH cx_sy_itab_line_not_found.
          l_result_4_checked-object    = object_type.
          l_result_4_checked-obj_name  = object_name.
      ENDTRY.

      lt_errors_o    = CORRESPONDING #( l_results ).
    ENDIF.

    SORT lt_errors_o BY object obj_name.  " providing SW and APPL componen

    CREATE DATA ref_object_name_ref.
    CREATE DATA ref_object_type_ref.
    CREATE DATA ref_package_ref.
    CREATE DATA application_component_ref.
    CREATE DATA ref_software_component_ref.

    " prepare to report and filter error finding
    LOOP AT lt_errors ASSIGNING <fs_error>.
      CLEAR: application_component, ref_software_component, ref_package, valid_finding.

      READ TABLE lt_errors_o ASSIGNING <error_complete> WITH KEY object   = <fs_error>-trobjtype
                                                               obj_name = <fs_error>-sobj_name.

** Begin of Change
*      if ( sy-subrc = 0 and (
*                belong_ref_obj_sap_or_partn( ref_obj_info =  <error_complete> ) = abap_true
*             or belng_ref_obj_cust_diff_dlvu( checked_obj_info = l_result_4_checked ref_obj_info  = <error_complete>  ) = abap_true
*             or <error_complete>-dlvunit <> l_result_4_checked-dlvunit   " when checkable_namespaces empty
*                            )
*          )
*        or ( is_enqueue_dequeue_reported( ref_obj_info = <fs_error> ) = abap_true ) .
      IF sy-subrc = 0.
** End of Change

        valid_finding = abap_true.  " report it by INFORM
      ELSE.
        " used object was not found or is within same DLVUNIT like checked object  => not report
        CONTINUE.
      ENDIF.

      CHECK valid_finding = abap_true.

      IF <error_complete> IS ASSIGNED.
        application_component_ref->*  = <error_complete>-ps_posid.
        application_component         = <error_complete>-ps_posid.
        ref_package_ref->*            = <error_complete>-devclass.
        ref_package                   = <error_complete>-devclass.
        ref_software_component        = <error_complete>-dlvunit.
        ref_software_component_ref->* = <error_complete>-dlvunit.
      ENDIF.

      IF <fs_error>-object_type IS NOT INITIAL AND  " treat released subobjects : func, badi definitions, CDS_STOB
        ( <fs_error>-object_type = 'FUNC' OR <fs_error>-object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition OR
          <fs_error>-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity ).

        IF <fs_error>-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
          ref_object_type  = 'STOB'.
        ELSEIF <fs_error>-object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition.
          ref_object_type  = 'BADI'.
        ELSE.
          ref_object_type = <fs_error>-object_type.
        ENDIF.

        ref_object_name = <fs_error>-sub_key.

        ref_object_type_ref->* = ref_object_type.
        ref_object_name_ref->* = <fs_error>-sub_key.

      ELSE.
        IF <fs_error>-trobjtype = 'ENHS' AND <fs_error>-object_type = 'ENHS'.
          CONTINUE. " spot standalone cannot be released for usage, skip
        ENDIF.
        ref_object_type = <fs_error>-trobjtype.
        ref_object_name = <fs_error>-sobj_name.

        ref_object_type_ref->* = <fs_error>-trobjtype.
        ref_object_name_ref->* = <fs_error>-sobj_name.
      ENDIF.

      kind   = c_error.
      line   = 1.
      column = 1.
      CLEAR msg.

      IF  <fs_error>-object_type IS NOT INITIAL AND <fs_error>-object_type = 'FUNC'.
        LOOP AT api_messages REFERENCE INTO DATA(lr_message) WHERE trobjtype = 'FUNC' AND sobj_name = <fs_error>-sub_key(40) AND info = <fs_error>-info.
          msg = VALUE symsg( msgid = lr_message->message->if_t100_message~t100key-msgid
                                   msgno = lr_message->message->if_t100_message~t100key-msgno
                                   msgty = lr_message->message->msgty
                                   msgv1 = lr_message->message->msgv1
                                   msgv2 = lr_message->message->msgv2
                                   msgv3 = lr_message->message->msgv3
                                   msgv4 = lr_message->message->msgv4 ).
          EXIT.
        ENDLOOP.
      ELSE.
        LOOP AT api_messages REFERENCE INTO lr_message WHERE object_key = <fs_error>-object_key AND info = <fs_error>-info.
          msg = VALUE symsg( msgid = lr_message->message->if_t100_message~t100key-msgid
                                   msgno = lr_message->message->if_t100_message~t100key-msgno
                                   msgty = lr_message->message->msgty
                                   msgv1 = lr_message->message->msgv1
                                   msgv2 = lr_message->message->msgv2
                                   msgv3 = lr_message->message->msgv3
                                   msgv4 = lr_message->message->msgv4 ).
          EXIT.
        ENDLOOP.
      ENDIF.

** Begin of Change
      DATA(lt_sidbobj_chg_frm_git) = load_chng_sidbdet_from_git( )-objectChangeDetails.
      IF <fs_error>-trobjtype NE 'FUGR'.
        DATA(l_objtype) = <fs_error>-trobjtype.
        DATA(l_objname)  = <fs_error>-sobj_name.
      ELSE.
        l_objtype = <fs_error>-object_type.
        l_objname  = <fs_error>-sub_key.
      ENDIF.
      DATA(l_chg_descr_det) = VALUE #( lt_sidbobj_chg_frm_git[ tadirobject = l_objtype tadirobjname = l_objname ]-decsription OPTIONAL ).
** End of Change

      details = fill_details(
        i_ref_object_type_ref       = ref_object_type_ref
        i_ref_object_name_ref       = ref_object_name_ref
        i_application_component_ref = application_component_ref
        i_message                   = msg
        i_devclass_ref              = ref_package_ref
        i_software_component_ref    = ref_software_component_ref
** Begin of Change
        "i_additional_info           = NEW string( 'Refer Documentaion from here https://help.sap.com/doc/25831a740892478da87d3204dbbaf693/2023.000/en-US/loio49860f614e374155b143261fcb13782c_en.pdf' ) ).
        i_additional_info           = NEW string( l_chg_descr_det ) ).
** End of Change

      IF <error_complete> IS ASSIGNED AND belng_ref_obj_cust_diff_dlvu( checked_obj_info = l_result_4_checked
                                          ref_obj_info     = <error_complete> ) = abap_true.
        code = cl_cls_ci_result_environment=>co_text_diff_cust_swc.
      ELSE.
        code = determine_finding_code(
          i_application_component = application_component
          i_software_component    = ref_software_component
          i_object_name           = ref_object_name            " referenced artifact in finding!!
          i_object_type           = ref_object_type
          i_err_entry             = <fs_error>
           ).
      ENDIF.

      kind = COND #( WHEN msg IS NOT INITIAL THEN msg-msgty
                     WHEN code = cl_cls_ci_result_environment=>co_text_deprecated    THEN c_warning
                     WHEN code = cl_cls_ci_result_environment=>co_text_diff_cust_swc THEN c_warning
                     ELSE c_error ).

      IF ( program_name IS NOT INITIAL ).
        " report now every position for one(!) non-whitelisted object
        map_whitelist_err_to_all_pos(
          EXPORTING
            i_referenced_objects    = referenced_objects
            i_ref_object_type       = ref_object_type
            i_ref_object_name       = ref_object_name
            i_kind                  = kind
            i_code                  = code
            i_application_component = application_component
          CHANGING
            c_details               = details ).
      ELSE.
        report_finding_for_non_src(
          EXPORTING
            i_ref_object_type       = ref_object_type
            i_ref_object_name       = ref_object_name
            i_line                  = line
            i_column                = column
            i_kind                  = kind
            i_code                  = code
            i_application_component = application_component
          CHANGING
            c_details = details ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->RFC_API_EXISTS
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RESULT                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method RFC_API_EXISTS.

    data msg type c length 255.

    if remote_api_exists = abap_true.
      result = abap_true.
      return.
    else.
      result = abap_false.
    endif.

    call function 'FUNCTION_EXISTS' destination l_destination
      exporting
        funcname              = 'RS_ABAP_GET_DDL_DEPENDENCIES_E'
      exceptions
        function_not_exist    = 1
        communication_failure = 2 message msg
        system_failure        = 3 message msg
        others                = 4.
    if sy-subrc = 0.
      result            = abap_true.
      remote_api_exists = abap_true.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHECK_ENV->RFC_API_OBJ_INFO_EXISTS
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RESULT                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method RFC_API_OBJ_INFO_EXISTS.

    data msg type c length 255.

    if remote_api_obj_info_exists = abap_true.
      result = abap_true.
      return.
    else.
      result = abap_false.
    endif.

    call function 'FUNCTION_EXISTS' destination l_destination
      exporting
        funcname              = 'RS_ABAP_GET_OBJECTS_INFOS_E'
      exceptions
        function_not_exist    = 1
        communication_failure = 2 message msg
        system_failure        = 3 message msg
        others                = 4.
    if sy-subrc = 0.
      result                     = abap_true.
      remote_api_obj_info_exists = abap_true.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->RUN
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method RUN.
    data:
      root_object           type sych_object_entry,
      usages                type sych_object_usage,
      usage                 type sych_object_usage_entry,
      errors                type sych_object_usage,
      environment_tab       type senvi_tab,
      lt_referenced_objects type cl_ycm_fullname_processor=>tty_id_mapping,
      l_rest                type string.
    data p_dependencies type ddldependency_tab.
    data l_objectname type objectname.

    field-symbols <usag> type cl_ycm_fullname_processor=>ty_id_mapping.

    clear: me->srefs_program_complete, checkable_namespaces.

    loop at object_params assigning field-symbol(<l_object_param>) where kind = 'ONSP'.
      append  <l_object_param>-value to checkable_namespaces.
    endloop.

    test-seam set_root.
      root_object-trobjtype   = object_type.
      root_object-object_type = object_type.
      root_object-sobj_name   = object_name.
    end-test-seam.

    check root_object-object_type in typelist.

    object_type   = root_object-object_type.
    object_name   = root_object-sobj_name.

    if ( me->program_name is not initial ).
      " processing a source code artifact and get referenced artifacts
      process_srccode_artifact( importing e_referenced_objects = lt_referenced_objects ).

      loop at lt_referenced_objects assigning <usag> where ( tadir_obj_type is not initial and tadir_obj_name is not initial )
                                                        or ( tadir_obj_type = 'FUGR' or tadir_obj_type = 'FUGS' ).
        clear usage.
        " deal with FUNCs in special way  as needed by uc5check
        if ( <usag>-tadir_obj_type = 'FUGR' or <usag>-tadir_obj_type = 'FUGS' ) and  <usag>-fullname+1(3) = 'FU:'.
          usage-trobjtype   = 'FUNC'.
          usage-object_type = 'FUNC'.
          split <usag>-fullname at ':' into l_rest usage-sobj_name.
        else.
          usage-object_type = <usag>-tadir_obj_type.
          usage-trobjtype   = <usag>-tadir_obj_type.
          usage-sobj_name   = <usag>-tadir_obj_name.

          " STOB / VIEWS behind CDS need to be treated a bit differently
          if ( usage-object_type = 'STOB' or usage-object_type = 'VIEW' ) and rfc_api_exists( ) = abap_true.
            l_objectname = <usag>-tadir_obj_name.
            p_dependencies = get_ddl_dependencies( exporting objectname = l_objectname ).
            read table p_dependencies with key objectname = l_objectname objecttype = usage-object_type assigning field-symbol(<fs_entry>).
            if sy-subrc = 0.
              usage-trobjtype   = 'DDLS'.
              usage-sobj_name   = <fs_entry>-ddlname.   "ddls name
              usage-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
              usage-sub_key     = l_objectname.         "cds entity name
            endif.
          elseif usage-object_type = 'BADI'.
            " ENHS  VER29850_ENHS BADI_DEF  VER29850_BADI_007
            l_objectname = <usag>-tadir_obj_name.
            select single enhspotname from badi_spot into @data(badi_enhs_name)
            where badi_name = @l_objectname.

            usage-trobjtype   = 'ENHS'.
            usage-sobj_name   = badi_enhs_name. " Spot name
            usage-object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition.
            usage-sub_key     = l_objectname.   " BAdI name
          endif.
        endif.
        append usage to usages.

        if usage-object_type = 'BDEF'. " BDEF refer at least to a DDLS with same name => add DDLS to usages
          clear usage.
          l_objectname   = <usag>-tadir_obj_name.
          p_dependencies = get_ddl_dependencies( exporting objectname = l_objectname ).
          read table p_dependencies with key ddlname = l_objectname objecttype = 'STOB' assigning <fs_entry>.
          if sy-subrc = 0.
            usage-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
            usage-trobjtype   = 'DDLS'.
            usage-sobj_name   = <fs_entry>-ddlname.    "ddls name
            usage-sub_key     = <fs_entry>-objectname. "cds entity name
            append usage to usages.
          endif.
        endif.
      endloop.
    else.
      " processing a non source code artifact (calculate environment)
      if object_type = 'VIEW' and rfc_api_exists( ) = abap_true.
        l_objectname = object_name.
        p_dependencies = get_ddl_dependencies( exporting objectname = l_objectname ).
        read table p_dependencies with key objectname = object_name assigning <fs_entry>.
        if sy-subrc = 0 and <fs_entry>-ddlname is not initial.
          return.  " it's a CDS-view, do not check
        endif.
      endif.

      if object_type  = 'DDLS' and rfc_api_exists( ) = abap_true.
        l_objectname = object_name.
        p_dependencies = get_ddl_dependencies( exporting objectname = l_objectname ).
        read table p_dependencies with key objecttype = 'STOB' ddlname = l_objectname assigning <fs_entry>.
        if sy-subrc = 0 .
          root_object-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
          root_object-trobjtype   = 'DDLS'.
          root_object-sobj_name   = <fs_entry>-ddlname.    "ddls name
          root_object-sub_key     = <fs_entry>-objectname. "cds entity name
        endif.
      endif.

      process_non_srccode_artifact(
        importing
          environment_tab   = environment_tab
        exceptions
          rfc_call_error    = 1
          others            = 2  ).
      if sy-subrc <> 0.
        return.
      endif.

      if object_type = 'ENHO'.
        try.
            data(l_enhs) = environment_tab[ type = 'ENHS' ]. " search for a spot in ENHO

            loop at environment_tab transporting no fields where encl_obj = l_enhs-object and type = swbm_c_type_cbadi_def.
              exit. " ok a good one, go on with the check
            endloop.
            if sy-subrc <> 0.
              return.  " source code plug-in, go out
            endif.
          catch cx_sy_itab_line_not_found.
            " an ENHO of an implicit enh. point as no spot assigned => go out will checked with sourcec ode compilation unit
            return.
        endtry.
      endif.

      loop at environment_tab assigning field-symbol(<env>)
                              where ( type+3 is not initial and type <> 'MESS' and
                                    type <> 'INCL' ) or type = swbm_c_type_cbadi_def.
        if <env>-type = 'STRU'. " as STRU is not a valid tadir type
          <env>-type = 'TABL'.
        endif.

        clear usage.

        usage-object_type = <env>-type.
        usage-trobjtype   = <env>-type.
        usage-sobj_name   = <env>-object.

        if <env>-type = swbm_c_type_cbadi_def.
          usage-trobjtype   = 'ENHS'.
          usage-sobj_name   =  <env>-encl_obj. " Spot name
          usage-object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition.
          usage-sub_key     = <env>-object.   " BAdI def name
        elseif <env>-type = 'DDLS' and rfc_api_exists( ) = abap_true.
          l_objectname = usage-sobj_name.
          p_dependencies = get_ddl_dependencies( exporting objectname = l_objectname ).
          read table p_dependencies with key objecttype = 'STOB' ddlname = l_objectname assigning <fs_entry>.
          if sy-subrc = 0 .
            usage-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
            usage-trobjtype   = 'DDLS'.
            usage-sobj_name   = <fs_entry>-ddlname.    "ddls name
            usage-sub_key     = <fs_entry>-objectname. "cds entity name
          endif.
        endif.

        append usage to usages.
      endloop.
    endif.

    sort   usages.
    delete adjacent duplicates from usages.

    errors = do_check(
       i_root_object = root_object
       i_usages      = usages ).

    " currently no difference in reporting UC2 and UC5 errors
    me->report_uc5check_errors(
     exporting
       referenced_objects =  lt_referenced_objects
     changing
      errors = errors  ).

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->RUN_BEGIN
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method RUN_BEGIN.
    cl_abap_source_id=>get_destination( exporting p_srcid      = srcid
                                       receiving p_destination = me->l_destination
                                       exceptions not_found    = 1 )   ##SUBRC_OK.

    clear: ddypes_resolved, tadir_resolved.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHECK_ENV->VERIFY_TEST
* +-------------------------------------------------------------------------------------------------+
* | [<-->] P_MESSAGES                     TYPE        SCIT_VERIFY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method VERIFY_TEST.
    data msg_verify  type line of scit_verify.

    super->verify_test( changing p_messages = p_messages ).

    cl_abap_source_id=>get_destination( exporting p_srcid       = srcid
                                        receiving p_destination = me->l_destination
                                        exceptions not_found    = 1 )   ##SUBRC_OK.
    if rfc_api_exists( ) = abap_false.
      clear msg_verify.
      msg_verify-test   = me->myname.
      msg_verify-code   = mcode___rfc_error__.
      msg_verify-kind   = c_error.
      msg_verify-text   = mtext___rfc_error__.
      msg_verify-param1 = 'RS_ABAP_GET_DDL_DEPENDENCIES_E'.
      append msg_verify to p_messages.
    endif.

    if rfc_api_obj_info_exists( ) = abap_false.
      clear msg_verify.
      msg_verify-test   = me->myname.
      msg_verify-code   = mcode___rfc_error__.
      msg_verify-kind   = c_error.
      msg_verify-text   = mtext___rfc_error__.
      msg_verify-param1 = 'RS_ABAP_GET_OBJECTS_INFOS_E'.
      append msg_verify to p_messages.
    endif.
  endmethod.
ENDCLASS.
