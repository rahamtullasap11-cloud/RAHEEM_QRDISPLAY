CLASS zcl_qr_generators DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS generate_qr
      IMPORTING
        iv_text       TYPE string
      RETURNING
        VALUE(rv_url) TYPE string
      RAISING
        cx_web_http_client_error
        cx_http_dest_provider_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_qr_generators IMPLEMENTATION.


  METHOD generate_qr.
    DATA(lv_encoded_text) =
       escape(
         val    = iv_text
         format = cl_abap_format=>e_url
       ).

    rv_url =
      |https://api.qrserver.com/v1/create-qr-code/?size=300x300&data={ lv_encoded_text }|.

*    DATA:
*      lo_http_client TYPE REF TO if_web_http_client,
*      lo_request     TYPE REF TO if_web_http_request,
*      lo_response    TYPE REF TO if_web_http_response,
*      lv_encoded     TYPE string,
*      lv_url         TYPE string.
*
*    "------------------------------------------------------------
*    " URL encode the text which has to be converted into QR
*    "------------------------------------------------------------
*    lv_encoded =
*      escape(
*        val    = iv_text
*        format = cl_abap_format=>e_url
*      ).
*
*    "------------------------------------------------------------
*    " QR Server URL
*    "------------------------------------------------------------
*    lv_url =
*      |https://api.qrserver.com/v1/create-qr-code/?size=300x300&data={ lv_encoded }|.
*
*    "------------------------------------------------------------
*    " Create HTTP client
*    "
*    " For a production BTP system, use a Destination instead
*    " of directly depending on an external URL.
*    "------------------------------------------------------------
*    lo_http_client =
*      cl_web_http_client_manager=>create_by_http_destination(
*        cl_http_destination_provider=>create_by_url(
*          i_url = lv_url
*        )
*      ).
*
*    "------------------------------------------------------------
*    " Get request
*    "------------------------------------------------------------
*    lo_request = lo_http_client->get_http_request( ).
*
*    lo_request->set_header_field(
*      i_name  = 'Accept'
*      i_value = 'image/png'
*    ).
*
*    "------------------------------------------------------------
*    " Execute GET request
*    "------------------------------------------------------------
*    lo_response =
*      lo_http_client->execute(
*        if_web_http_client=>get
*      ).
*
*    "------------------------------------------------------------
*    " Check HTTP status
*    "------------------------------------------------------------
*    DATA(ls_status) = lo_response->get_status( ).
*
*    IF ls_status-code <> 200.
*
*      RAISE EXCEPTION TYPE cx_web_http_client_error.
*
*    ENDIF.
*
*    "------------------------------------------------------------
*    " Get generated QR image
*    "------------------------------------------------------------
*    rv_image = lo_response->get_binary( ).
*
*    "------------------------------------------------------------
*    " Close client
*    "------------------------------------------------------------
*    lo_http_client->close( ).

  ENDMETHOD.



ENDCLASS.
