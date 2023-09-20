class ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF definition
  public
  inheriting from ZCL_CCM_CLS_CI_CHECK_ENV
  final
  create public .

public section.

  methods CONSTRUCTOR .
  methods SET_PARAMETERS
    importing
      !P_URL type SYCM_URL optional .

  methods GET_ATTRIBUTES
    redefinition .
  methods IF_CI_TEST~QUERY_ATTRIBUTES
    redefinition .
  methods PUT_ATTRIBUTES
    redefinition .
  methods RUN_BEGIN
    redefinition .
  methods VERIFY_TEST
    redefinition .
protected section.

  data PA_URL type SYCM_URL .

  methods DETERMINE_FINDING_CODE
    redefinition .
  methods DO_UC5CHECK
    redefinition .
  methods GET_SUCCESSOR
    redefinition .
private section.

  types:
    begin of ty_entry_flat,
        object_type type trobjtype,
        object_name type sobj_name,
      end of ty_entry_flat .
  types:
    t_entries_flat type standard table of ty_entry_flat with non-unique default key .

  data LT_RELEASED_OBJECTS type T_ENTRIES_FLAT .
  data LT_DEPRECATED_OBJECTS type T_ENTRIES_FLAT .
  data LT_NOT_TO_BE_REL_OBJECTS type T_ENTRIES_FLAT .
  data LT_DEPRECATED_FULL type IF_AFF_RELEASED_CHECK_OBJS=>TY_MAIN-OBJECT_RELEASE_INFO .
  data LT_NOT_TO_BE_REL_FULL type IF_AFF_RELEASED_CHECK_OBJS=>TY_MAIN-OBJECT_RELEASE_INFO .
  data ERROR_MESSAGE type STRING .
  data CLIENT type ref to IF_HTTP_CLIENT .
  constants MCODE___HTTP_ERROR__ type SCI_ERRC value '__HTTPER__' ##NO_TEXT.

  methods LOAD_OBJS_CLOUDIFICATION_DB .
  methods ACCESS_CLIENT_AT_URL
    exporting
      !E_CLIENT type ref to IF_HTTP_CLIENT .
ENDCLASS.



CLASS ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->ACCESS_CLIENT_AT_URL
* +-------------------------------------------------------------------------------------------------+
* | [<---] E_CLIENT                       TYPE REF TO IF_HTTP_CLIENT
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method ACCESS_CLIENT_AT_URL.

    clear me->error_message.

    cl_http_client=>create_by_url(
        exporting
          url                        = conv #( pa_url )
        importing
          client                     = e_client
        exceptions
          argument_not_found         = 1
          plugin_not_active          = 2
          internal_error             = 3
          pse_not_found              = 4
          pse_not_distrib            = 5
          pse_errors                 = 6
          oa2c_set_token_error       = 7
          oa2c_missing_authorization = 8
          oa2c_invalid_config        = 9
          oa2c_invalid_parameters    = 10
          oa2c_invalid_scope         = 11
          oa2c_invalid_grant         = 12
          others                     = 13     ).
    if sy-subrc <> 0.
      if sy-msgid is not initial.
        message id sy-msgid type 'S' number sy-msgno with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 into me->error_message.
      endif.

      clear e_client.
      return.
    endif.

    e_client->send(
      exceptions
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        http_invalid_timeout       = 4
        others                     = 5     ).
    if sy-subrc <> 0.
      e_client->get_last_error(
        importing
          message        =   me->error_message   ).

      clear e_client.
      return.
    endif.

    e_client->receive(
      exceptions
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        others                     = 4   ).

    if sy-subrc <> 0.
      e_client->get_last_error(
        importing
          message        =   me->error_message   ).

      CLEAR e_client.
      RETURN.
    ENDIF.

    e_client->response->get_status( IMPORTING code = DATA(status_code)  ).

    IF status_code = 200 .
      DATA(content_type) = client->response->get_content_type( ).

      IF content_type NP 'text/plain;*'.
        me->error_message = 'Content from client is not the expected one'(097).
        CLEAR e_client.
        RETURN.
      ENDIF.
    ELSE.
      me->error_message = | Error: client->response->get_status { status_code } |.
      clear e_client.
      return.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method CONSTRUCTOR.
    super->constructor( ).

*     'Usage of Released APIs (Cloudification Repository)'(000).
    description = 'Custom GTS Simplification Check'.
    category    = 'CL_CI_CATEGORY_CLOUD_READINESS'.
    version     = '000'.
    position    = '011'.

    remote_rfc_enabled = abap_true.
    has_attributes     = abap_true.
    has_documentation  = abap_true.

    clear smsg.
    smsg-test     = me->myname.
    smsg-code     = mcode___http_error__.
    smsg-category = c_cat_not_executable_at_all.
    smsg-kind     = 'E'.
    smsg-text     = 'Error when accessing cloudification repository at provided URL (&1) '(099).
    smsg-pcom     = c_exceptn_imposibl.
    insert smsg into table scimessages.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->DETERMINE_FINDING_CODE
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_APPLICATION_COMPONENT        TYPE        DF14L-PS_POSID
* | [--->] I_SOFTWARE_COMPONENT           TYPE        DLVUNIT
* | [--->] I_OBJECT_TYPE                  TYPE        TROBJTYPE
* | [--->] I_OBJECT_NAME                  TYPE        SOBJ_NAME
* | [--->] I_ERR_ENTRY                    TYPE        SYCH_OBJECT_USAGE_ENTRY
* | [<-()] R_CODE                         TYPE        SCI_ERRC
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method DETERMINE_FINDING_CODE.
    data l_object_type type trobjtype.

    if i_err_entry-object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition or i_object_type = 'BADI'.
      l_object_type       = 'BADI'.
      data(l_object_name) = i_err_entry-sub_key.
    elseif i_err_entry-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity or i_object_type = 'STOB'.
      l_object_type = 'STOB'.
      l_object_name = i_err_entry-sub_key.
    else.
      l_object_type = i_object_type.
      l_object_name = i_object_name.
    endif.

    if line_exists( lt_deprecated_objects[  object_type = l_object_type object_name = l_object_name ] ).
      r_code = mcode_deprecated.
    elseif line_exists( lt_not_to_be_rel_objects[ object_type = l_object_type object_name = l_object_name ] ).
      r_code = mcode_not_to_rel.
    else.
      if i_software_component = 'SAP_BASIS' or i_software_component = 'SAP_ABA' or
         i_software_component = 'SAP_GWFND'.
        r_code = mcode_forbidden.
      elseif i_software_component = 'SAP_UI'.
        r_code = mcode_forbidden_ui.
      else.
        r_code = mcode_forbidden_app.
      endif.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->DO_UC5CHECK
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_ROOT_OBJECT                  TYPE        SYCH_OBJECT_ENTRY
* | [--->] I_USAGES                       TYPE        SYCH_OBJECT_USAGE
* | [<-()] R_ERRORS                       TYPE        SYCH_OBJECT_USAGE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method DO_UC5CHECK.
    " check used objects against released objects provided by repository content
    data ls_message type sych_object_usage_message.

    IF ( lt_released_objects IS INITIAL AND lt_deprecated_objects IS INITIAL AND
         lt_not_to_be_rel_objects IS INITIAL ).
      RETURN.  " something went wrong with content from repository
    ENDIF.

    clear: r_errors, me->api_messages.

** Begin of Change
    DATA(lt_sidbobj_chg_frm_git) = load_chng_sidbdet_from_git( )-objectChangeDetails.
** End of Change

    loop at i_usages assigning field-symbol(<fs_usag>).
** Begin of Adjustment **
      IF <fs_usag>-trobjtype NE 'FUGR'.
        DATA(l_objtype) = <fs_usag>-trobjtype.
        DATA(l_objname)  = <fs_usag>-sobj_name.
      ELSE.
        l_objtype  = <fs_usag>-object_type.
        l_objname  = <fs_usag>-sub_key.
      ENDIF.
*      check <fs_usag>-trobjtype is not initial and <fs_usag>-object_type is not initial and
*            <fs_usag>-sobj_name is not initial.
      check <fs_usag>-trobjtype is not initial and <fs_usag>-object_type is not initial and
            <fs_usag>-sobj_name is not initial
            and ( line_exists( lt_deprecated_objects[ object_name = <fs_usag>-sobj_name object_type = <fs_usag>-object_type ] )
                  or line_exists( lt_deprecated_full[ tadir_obj_name = <fs_usag>-sobj_name object_type = <fs_usag>-object_type ] )
                  or line_exists( lt_not_to_be_rel_full[ tadir_obj_name = <fs_usag>-sobj_name object_type = <fs_usag>-object_type ] )
                  or line_exists( lt_not_to_be_rel_objects[ object_name = <fs_usag>-sobj_name object_type = <fs_usag>-object_type ] )
                  or line_exists( lt_released_objects[ object_name = <fs_usag>-sobj_name object_type = <fs_usag>-object_type ] ) ).
** End of Adjustment **

      if  ( <fs_usag>-object_type = 'TYPE' and <fs_usag>-sobj_name = 'ABAP' ).
        continue.
      endif.

      if <fs_usag>-object_type = if_ars_abap_object_check=>gc_sub_object_type-badi_definition.
        data(l_object_type) = 'BADI'.
        data(l_object_name) = <fs_usag>-sub_key.
      elseif <fs_usag>-object_type = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
        l_object_type = 'STOB'.
        l_object_name = <fs_usag>-sub_key.
      else.
        l_object_type = <fs_usag>-trobjtype.
        l_object_name = <fs_usag>-sobj_name.
      endif.

      " extremely simplified check vs. released objects provided by cloudification repository
      read table lt_released_objects with key object_type = l_object_type
                                              object_name = l_object_name transporting no fields.
      if sy-subrc <> 0.
        " not within released, ATC finding-candidate
        append <fs_usag> to r_errors.
        clear ls_message.

        if l_object_type = 'STOB' .
          data(l_object_type_ars) = if_ars_abap_object_check=>gc_sub_object_type-cds_entity.
          data(l_object_name_ars) = <fs_usag>-sub_key.
        elseif l_object_type = 'BADI' .
          l_object_type_ars = if_ars_abap_object_check=>gc_sub_object_type-badi_definition.
          l_object_name_ars = <fs_usag>-sub_key.
        else.
          l_object_type_ars = l_object_type.
          l_object_name_ars = l_object_name.
        endif.

        " get better details for message code
        read table lt_deprecated_full assigning field-symbol(<fs_deprecated>) with key object_type = l_object_type_ars
                                                                                       object_key  = l_object_name_ars.
        if sy-subrc = 0.
          move-corresponding <fs_usag> to ls_message.
          if <fs_deprecated>-successor_classification = '1' and <fs_deprecated>-successors is not initial.
** Begin of Change
            " if successor and predecessor are same then its change!
            IF <fs_usag>-object_key-sobj_name EQ <fs_deprecated>-successors[ 1 ]-tadir_object.
              ls_message-message = new cm_cls_api_abap_obj_ucacheck(
                iv_msgid = 'ZCCM_GTS_MESSAGE' " Messsage class with below message must be created!
                iv_msgty = 'W'
                iv_msgno = '000' "&1 is Changed. Please see object documentation for Details.
                iv_msgv1 = conv #( <fs_usag>-object_key-trobjtype )
                iv_msgv2 = conv #( <fs_usag>-object_key-sobj_name ) ).
** End of Change
            ELSE.
              ls_message-message = new cm_cls_api_abap_obj_ucacheck(
                iv_msgid = 'LA'
                iv_msgty = 'W'
                iv_msgno = '021'
                iv_msgv1 = conv #( <fs_usag>-object_key-trobjtype )
                iv_msgv2 = conv #( <fs_usag>-object_key-sobj_name )
                iv_msgv3 = conv #( <fs_deprecated>-successors[ 1 ]-tadir_object )
                iv_msgv4 = conv #( <fs_deprecated>-successors[ 1 ]-tadir_obj_name ) ).
            ENDIF.
          ELSEIF <fs_deprecated>-successor_classification = 'X' AND <fs_deprecated>-successor_concept_name IS NOT INITIAL.
            ls_message-message = NEW cm_cls_api_abap_obj_ucacheck(
              iv_msgid = 'CLS_CHECK_ENVIRONM'
              iv_msgty = 'W'
              iv_msgno = '017'
              iv_msgv1 = CONV #( <fs_usag>-object_key-trobjtype )
              iv_msgv2 = CONV #( <fs_usag>-object_key-sobj_name )
              iv_msgv4 = <fs_deprecated>-successor_concept_name     ).
          ELSEIF lines( <fs_deprecated>-successors ) > 1.
            ls_message-message = new cm_cls_api_abap_obj_ucacheck(
               iv_msgid = 'LA'
               iv_msgty = 'W'
               iv_msgno = '022'
               iv_msgv1 = conv #( <fs_usag>-object_key-trobjtype )
               iv_msgv2 = conv #( <fs_usag>-object_key-sobj_name ) ).
          endif.
          if ls_message-message is bound.
** Begin of Change
            ls_message-info = VALUE #( lt_sidbobj_chg_frm_git[ tadirobject = l_objtype tadirobjname = l_objname ]-decsription OPTIONAL ).
** End of Change
            insert ls_message into table api_messages.
          endif.
        else.

          read table lt_not_to_be_rel_full assigning field-symbol(<fs_not_to_be>) with key object_type = l_object_type_ars
                                                                                           object_key  = l_object_name_ars.
          if sy-subrc = 0.
            move-corresponding <fs_usag> to ls_message.
            if <fs_not_to_be>-successor_classification = '1' and <fs_not_to_be>-successors is not initial.
              ls_message-message = new cm_cls_api_abap_obj_ucacheck(
                iv_msgid = 'LA'
                iv_msgty = 'E'
                iv_msgno = '026'
                iv_msgv1 = conv #( <fs_usag>-object_key-trobjtype )
                iv_msgv2 = conv #( <fs_usag>-object_key-sobj_name )
                iv_msgv3 = conv #( <fs_not_to_be>-successors[ 1 ]-tadir_object )
                iv_msgv4 = conv #( <fs_not_to_be>-successors[ 1 ]-tadir_obj_name ) ).
            ELSEIF <fs_not_to_be>-successor_classification = 'X' AND <fs_not_to_be>-successor_concept_name IS NOT INITIAL.
              ls_message-message = NEW cm_cls_api_abap_obj_ucacheck(
                iv_msgid = 'CLS_CHECK_ENVIRONM'
                iv_msgty = 'E'
                iv_msgno = '031'
                iv_msgv1 = CONV #( <fs_usag>-object_key-trobjtype )
                iv_msgv2 = CONV #( <fs_usag>-object_key-sobj_name )
                iv_msgv4 = <fs_not_to_be>-successor_concept_name     ).
            ELSEIF lines( <fs_not_to_be>-successors ) > 1.
              ls_message-message = new cm_cls_api_abap_obj_ucacheck(
                 iv_msgid = 'LA'
                 iv_msgty = 'E'
                 iv_msgno = '027'
                 iv_msgv1 = conv #( <fs_usag>-object_key-trobjtype )
                 iv_msgv2 = conv #( <fs_usag>-object_key-sobj_name ) ).
            endif.
            if ls_message-message is bound.
** Begin of Change
              ls_message-info = VALUE #( lt_sidbobj_chg_frm_git[ tadirobject = l_objtype tadirobjname = l_objname ]-decsription OPTIONAL ).
** End of Change
              insert ls_message into table api_messages.
            endif.
          endif.
        endif.
      endif.
    endloop.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->GET_ATTRIBUTES
* +-------------------------------------------------------------------------------------------------+
* | [<-()] P_ATTRIBUTES                   TYPE        XSTRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_ATTRIBUTES.
    export pa_url = pa_url to data buffer p_attributes.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->GET_SUCCESSOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_REF_OBJECT_NAME              TYPE        SOBJ_NAME
* | [--->] I_OBJECT_TYPE                  LIKE        IF_ARS_ABAP_OBJECT_CHECK=>GC_SUB_OBJECT_TYPE-CDS_ENTITY
* | [<-()] R_REPLACEMENT                  TYPE        TY_SUCCESSOR
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_SUCCESSOR.
    read table lt_deprecated_full with key  object_type = i_object_type
                                            object_key  = i_ref_object_name
                                            successor_classification = '1' assigning field-symbol(<fs_deprecated>).
    if sy-subrc <> 0.
      read table lt_not_to_be_rel_full with key  object_type = i_object_type
                                                 object_key  = i_ref_object_name
                                                 successor_classification = '1' assigning field-symbol(<fs_not_to_be>).
    endif.

    if <fs_deprecated> is assigned and <fs_deprecated>-successors is not initial.
      move-corresponding <fs_deprecated> to r_replacement.
      r_replacement-successor_tadir_object   = <fs_deprecated>-successors[ 1 ]-tadir_object.
      r_replacement-successor_tadir_obj_name = <fs_deprecated>-successors[ 1 ]-tadir_obj_name.
      r_replacement-successor_object_key     = <fs_deprecated>-successors[ 1 ]-object_key.
      r_replacement-successor_object_type    = <fs_deprecated>-successors[ 1 ]-object_type.
    elseif <fs_not_to_be> is assigned and <fs_not_to_be>-successors is not initial.
      move-corresponding <fs_not_to_be> to r_replacement.
      r_replacement-successor_tadir_object   = <fs_not_to_be>-successors[ 1 ]-tadir_object.
      r_replacement-successor_tadir_obj_name = <fs_not_to_be>-successors[ 1 ]-tadir_obj_name.
      r_replacement-successor_object_key     = <fs_not_to_be>-successors[ 1 ]-object_key.
      r_replacement-successor_object_type    = <fs_not_to_be>-successors[ 1 ]-object_type.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->IF_CI_TEST~QUERY_ATTRIBUTES
* +-------------------------------------------------------------------------------------------------+
* | [--->] P_DISPLAY                      TYPE        FLAG (default =' ')
* | [--->] P_IS_ADT                       TYPE        ABAP_BOOL (default =ABAP_FALSE)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method IF_CI_TEST~QUERY_ATTRIBUTES.
    data:
      l_attributes     type sci_atttab,
      l_popup_canceled type abap_bool,
      l_url            TYPE sycm_url,
      l_message        TYPE c LENGTH 72.

    l_attributes = value #(
                            ( id = `Url` ref = ref #( l_url ) text = text-url kind = cl_ci_query_attributes=>c_attribute_kinds-elementary )
                          ).

    l_url = pa_url.

    do.
      " Show a pop-up with parameters of the CI Check
      l_popup_canceled = cl_ci_query_attributes=>generic( p_name       = myname
                                                          p_title      = 'Check Usage of Released Objects (taken from Cloudification Repository)'(100)
                                                          p_attributes = l_attributes
                                                          p_display    = p_display
                                                          p_message    = l_message ).
      IF l_popup_canceled = abap_true.
        RETURN.
      ENDIF.

** Begin of Change
*      IF l_url NP 'https://raw.githubusercontent.com/SAP/abap-atc-cr-cv-s4hc/main/src/objectReleaseInfo*.json'.
*        l_message = 'Specified URL is not allowed'(098).
*        attributes_ok = abap_false.
*        continue.
*      ELSE.
*        CLEAR l_message.
*      endif.
** End of Change
      attributes_ok    = 'X'.

      if p_display = 'X'.
        " in display mode => go out
        return.
      endif.

      pa_url = l_url.

      return.

    enddo.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->LOAD_OBJS_CLOUDIFICATION_DB
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method LOAD_OBJS_CLOUDIFICATION_DB.
    data l_main                        type if_aff_released_check_objs=>ty_main.
    data lt_ars_apis_released_4_c1_scp type if_aff_released_check_objs=>ty_main-object_release_info.
    data lt_messages  type scit_verify.

    clear  me->error_message.

    if me->client is not bound.
      access_client_at_url(
        importing
          e_client      = me->client ).
    endif.

    if me->client is bound.
      DATA(body)   = client->response->get_data( ).
      DATA(reader) = cl_sxml_string_reader=>create( body ).

        call transformation sycm_xslt_released_check_objs
          source xml reader
          result root = l_main.

        lt_ars_apis_released_4_c1_scp = l_main-object_release_info.

        if lt_ars_apis_released_4_c1_scp is initial.
        me->error_message = 'No object release information was readed'(112).
          return.                     " !!!! go out
        endif.

        loop at lt_ars_apis_released_4_c1_scp assigning field-symbol(<object>) where state = 'RELEASED'.
          if ( <object>-object_type = 'BADI_DEF' ).
            insert value #( object_type = 'BADI' object_name = <object>-object_key ) into table me->lt_released_objects.
          elseif ( <object>-object_type = 'CDS_STOB' ).
            insert value #( object_type = 'STOB' object_name = <object>-object_key ) into table me->lt_released_objects.
          elseif ( <object>-object_type = 'FUNC' ).
            insert value #( object_type = 'FUNC' object_name = <object>-object_key ) into table me->lt_released_objects.
          else.
            insert value #( object_type = <object>-tadir_object object_name = <object>-tadir_obj_name ) into table me->lt_released_objects.
          endif.
        endloop.

        " successor is of importance, keep complete info from repository
        loop at lt_ars_apis_released_4_c1_scp assigning <object> where state = 'DEPRECATED'.
          if ( <object>-object_type = 'BADI_DEF' ).
            insert value #( object_type = 'BADI' object_name = <object>-object_key ) into table me->lt_deprecated_objects.
          elseif ( <object>-object_type = 'CDS_STOB' ).
            insert value #( object_type = 'STOB' object_name = <object>-object_key ) into table me->lt_deprecated_objects.
          elseif ( <object>-object_type = 'FUNC' ).
            insert value #( object_type = 'FUNC' object_name = <object>-object_key ) into table me->lt_deprecated_objects.
          else.
            insert value #( object_type = <object>-tadir_object object_name = <object>-tadir_obj_name ) into table me->lt_deprecated_objects.
          endif.

          insert <object> into table lt_deprecated_full.
        endloop.

        loop at lt_ars_apis_released_4_c1_scp assigning <object> where ( state = 'NOT_TO_BE_RELEASED' or
                                                                         state = 'NOT_TO_BE_RELEASED_STABLE' ).
          if ( <object>-object_type = 'BADI_DEF' ).
            insert value #( object_type = 'BADI' object_name = <object>-object_key ) into table me->lt_not_to_be_rel_objects.
          elseif ( <object>-object_type = 'CDS_STOB' ).
            insert value #( object_type = 'STOB' object_name = <object>-object_key ) into table me->lt_not_to_be_rel_objects.
          elseif ( <object>-object_type = 'FUNC' ).
            insert value #( object_type = 'FUNC' object_name = <object>-object_key ) into table me->lt_not_to_be_rel_objects.
          else.
            insert value #( object_type = <object>-tadir_object object_name = <object>-tadir_obj_name ) into table me->lt_not_to_be_rel_objects.
          endif.

          insert <object> into table lt_not_to_be_rel_full.
        endloop.

    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->PUT_ATTRIBUTES
* +-------------------------------------------------------------------------------------------------+
* | [--->] P_ATTRIBUTES                   TYPE        XSTRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PUT_ATTRIBUTES.
    import pa_url = pa_url from data buffer p_attributes.
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->RUN_BEGIN
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method RUN_BEGIN.

    super->run_begin( ).

    me->load_objs_cloudification_db( ).

    if ( lt_released_objects is initial and lt_deprecated_objects is initial and
         lt_not_to_be_rel_objects is initial ) or me->error_message is not initial.

      inform( exporting  p_test          = me->myname
                         p_sub_obj_type = object_type
                         p_sub_obj_name = object_name
                         p_code         = mcode___http_error__
                         p_param_1      = error_message
                         p_checksum_1   = -1 ).
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->SET_PARAMETERS
* +-------------------------------------------------------------------------------------------------+
* | [--->] P_URL                          TYPE        SYCM_URL(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method SET_PARAMETERS.

    if p_url is supplied.
      pa_url = p_url.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF->VERIFY_TEST
* +-------------------------------------------------------------------------------------------------+
* | [<-->] P_MESSAGES                     TYPE        SCIT_VERIFY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method VERIFY_TEST.
    data ls_message      type scis_verify.

    super->verify_test( changing p_messages = p_messages ).

*    IF pa_url NP 'https://raw.githubusercontent.com/SAP/abap-atc-cr-cv-s4hc/main/src/objectReleaseInfo*.json'.
*      ls_message-test   = me->myname.
*      ls_message-code   = mcode___http_error__.
*      ls_message-kind   = 'E'.
*      ls_message-param1 = 'Specified URL is not allowed'(098).
*      APPEND ls_message TO p_messages.
*    ENDIF.

    cl_http_client=>create_by_url(
     exporting
       url                        = conv #( pa_url )
     importing
       client                     = data(client)
     exceptions
       argument_not_found         = 1
       plugin_not_active          = 2
       internal_error             = 3
       pse_not_found              = 4
       pse_not_distrib            = 5
       pse_errors                 = 6
       oa2c_set_token_error       = 7
       oa2c_missing_authorization = 8
       oa2c_invalid_config        = 9
       oa2c_invalid_parameters    = 10
       oa2c_invalid_scope         = 11
       oa2c_invalid_grant         = 12
       others                     = 13     ).
    if sy-subrc <> 0.
      if sy-msgid is not initial.
        message id sy-msgid type 'S' number sy-msgno with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 into me->error_message.
      endif.
      ls_message-test = me->myname.
      ls_message-code   = mcode___http_error__.
      ls_message-kind   = 'E'.
      ls_message-param1 = me->error_message.
      append ls_message to p_messages.
    endif.

  endmethod.
ENDCLASS.
